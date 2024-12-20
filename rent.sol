// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Rental_Contract {

    address public landlord;  // Арендодатель
    address public tenant;    // Арендатор
    uint256 public rentAmount; // Ежемесячная арендная плата
    uint256 public depositAmount; // Сумма предоплаты
    uint256 public rentDueDate;  // Дата следующего платежа
    uint256 public leaseStartDate;  // Дата начала аренды
    uint256 public leaseDuration;  // Продолжительность аренды в секундах
    uint256 public penaltyAmount;  // Штраф за просрочку
    bool public leaseActive; // Статус аренды
    bool public earlyTermination;  // Флаг досрочного расторжения
    uint256 public totalPaid; // Общая сумма, выплаченная арендатором

    // События
    event RentPaid(address tenant, uint256 amount);
    event LeaseTerminated(address tenant, uint256 penalty);
    event LeaseEnded(address tenant);
    event RentDue(address tenant, uint256 amount);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can perform this action");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can perform this action");
        _;
    }

    modifier leaseOngoing() {
        require(leaseActive, "Lease is not active");
        _;
    }

    modifier leaseEnded() {
        require(!leaseActive, "Lease is still active");
        _;
    }

    constructor(
        address _landlord,
        address _tenant,
        uint256 _rentAmount,
        uint256 _depositAmount,
        uint256 _leaseDuration,
        uint256 _penaltyAmount
    ) {
        landlord = _landlord;
        tenant = _tenant;
        rentAmount = _rentAmount;
        depositAmount = _depositAmount;
        leaseDuration = _leaseDuration;
        penaltyAmount = _penaltyAmount;
        leaseStartDate = block.timestamp;
        leaseActive = true;
        totalPaid = 0;
    }

    // Инициализация аренды и перевода предоплаты
    function initiateLease() external onlyTenant {
        require(totalPaid == 0, "Lease has already been initiated");
        // Платеж арендатором предоплаты (можно перевести напрямую в эфире для теста)
        payable(landlord).transfer(depositAmount);
        totalPaid += depositAmount;
        leaseStartDate = block.timestamp;
        rentDueDate = leaseStartDate + 30 days; // Платежи ежемесячно
        emit RentPaid(msg.sender, depositAmount);
    }

    // Платежи по аренде
    function payRent() external onlyTenant leaseOngoing {
        require(block.timestamp >= rentDueDate, "Rent payment is not due yet");
        // Платеж арендатором ежемесячной арендной платы
        payable(landlord).transfer(rentAmount);
        totalPaid += rentAmount;

        // Обновление даты следующего платежа
        rentDueDate += 30 days; // Следующий платеж через месяц
        emit RentPaid(msg.sender, rentAmount);
    }

    // Досрочное расторжение аренды (если это предусмотрено)
    function terminateLease() external onlyTenant leaseOngoing {
        require(!earlyTermination, "Lease is already terminated early");

        uint256 penalty = penaltyAmount;
        earlyTermination = true;
        leaseActive = false;

        // Возвращаем часть депозита, если это предусмотрено (например, за вычетом штрафа)
        uint256 refundAmount = depositAmount > penalty ? depositAmount - penalty : 0;

        // Переводим штраф и возврат арендатору
        payable(landlord).transfer(penalty);
        if (refundAmount > 0) {
            payable(tenant).transfer(refundAmount);
        }

        emit LeaseTerminated(msg.sender, penalty);
    }

    // Завершение аренды по окончании срока
    function endLease() external onlyLandlord leaseOngoing {
        require(block.timestamp >= leaseStartDate + leaseDuration, "Lease is not expired yet");

        leaseActive = false;
        uint256 refundAmount = depositAmount;

        // Переводим депозита арендатору
        payable(tenant).transfer(refundAmount);

        emit LeaseEnded(tenant);
    }

    // Проверка текущего баланса арендодателя
    function landlordBalance() external view returns (uint256) {
        return address(landlord).balance;
    }

    // Проверка текущего баланса арендатора
    function tenantBalance() external view returns (uint256) {
        return address(tenant).balance;
    }

    // Функция для получения оставшегося времени аренды
    function remainingLeaseTime() external view returns (uint256) {
        if (!leaseActive) return 0;
        return (leaseStartDate + leaseDuration) - block.timestamp;
    }
}

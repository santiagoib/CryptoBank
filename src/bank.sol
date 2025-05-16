// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CryptoBank
 * @notice A decentralized ETH vault with interest accrual functionality.
 * Users can deposit, claim interest, and withdraw. Admin can pause or update interest rate.
 */
contract CryptoBank is Ownable, Pausable, ReentrancyGuard {
    uint256 public constant MIN_DEPOSIT = 300000 gwei; // 0.3 ETH
    uint256 public constant MIN_WITHDRAW =  100000 gwei; // 0.1 ETH

    uint256 public interestRate; // in basis points (e.g. 500 = 5%)

    mapping(address => uint256) public ethBalances;
    mapping(address => uint256) public lastInterestClaim;

    event DepositETH(address indexed user, uint256 amount);
    event WithdrawETH(address indexed user, uint256 amount);
    event InterestPaid(address indexed user, uint256 amount);
    event InterestRateUpdated(uint256 newRate);
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    /**
     * @param initialOwner Initial owner of the contract.
     * @param interestRate_ Annual interest rate in basis points.
     */
    constructor(address initialOwner, uint256 interestRate_) Ownable(initialOwner) {
        interestRate = interestRate_;
    }

    modifier onlyPositive(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    // --- Admin Functions ---

    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function setInterestRate(uint256 newRate) external onlyOwner {
        require(newRate <= 1000, "Interest rate too high"); // max 10%
        interestRate = newRate;
        emit InterestRateUpdated(newRate);
    }

    // --- Public Functions ---

    function depositETH() public payable whenNotPaused onlyPositive(msg.value) nonReentrant {
    require(msg.value >= MIN_DEPOSIT, "Deposit below minimum");

    ethBalances[msg.sender] += msg.value;
    emit DepositETH(msg.sender, msg.value);
    _claimInterestInternal(msg.sender);
    }


    function withdrawETH(uint256 amount) external whenNotPaused onlyPositive(amount) nonReentrant {
        require(ethBalances[msg.sender] >= amount, "Insufficient balance");
        require(amount >= MIN_WITHDRAW, "Withdrawal below minimum");

        _claimInterestInternal(msg.sender);

        ethBalances[msg.sender] -= amount;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        emit WithdrawETH(msg.sender, amount);
    }

    function claimInterest() external whenNotPaused nonReentrant {
        _claimInterestInternal(msg.sender);
    }

    function calculateInterest(address user) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastInterestClaim[user];
        if (timeElapsed == 0 || ethBalances[user] == 0) return 0;

        uint256 yearlyInterest = (ethBalances[user] * interestRate) / 10000;
        return (yearlyInterest * timeElapsed) / 365 days;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal Functions ---

    function _claimInterestInternal(address user) internal {
        if (ethBalances[user] < MIN_DEPOSIT) return;

        uint256 interest = calculateInterest(user);
        if (interest == 0) return;

        ethBalances[user] += interest;
        lastInterestClaim[user] = block.timestamp;

        emit InterestPaid(user, interest);
    }

    // --- Fallback ---
receive() external payable {
    depositETH();
}

fallback() external payable {
    depositETH();
}

}
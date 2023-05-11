pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SafetyProtocol is ReentrancyGuard {
    address public owner;
    IERC20 public token;
    uint256 public constant WITHDRAWAL_LIMIT = 3 * 10**17; // 0.3 ETH in Wei
    address public withdrawalAddress;

    event Withdrawn(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(IERC20 _token, address _withdrawalAddress) {
        require(_withdrawalAddress != address(0), "Invalid withdrawal address");
        owner = msg.sender;
        token = _token;
        withdrawalAddress = _withdrawalAddress;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        token.transferFrom(msg.sender, address(this), _amount);
        if (address(this).balance >= WITHDRAWAL_LIMIT) {
            _withdraw();
        }
    }

    function _withdraw() private nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 amountToWithdraw = contractBalance < WITHDRAWAL_LIMIT ? contractBalance : WITHDRAWAL_LIMIT;
        (bool success, ) = withdrawalAddress.call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(amountToWithdraw);
    }

    function changeWithdrawalAddress(address _newWithdrawalAddress) external onlyOwner {
        require(_newWithdrawalAddress != address(0), "Invalid withdrawal address");
        withdrawalAddress = _newWithdrawalAddress;
    }
}

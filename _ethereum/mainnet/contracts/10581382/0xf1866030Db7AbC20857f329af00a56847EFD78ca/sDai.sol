pragma solidity ^0.6.0;

// import "./ERC20.sol";
// import "./ERC20Detailed.sol";

// import "./SavingsManager.sol";

// /// @title Savings Dai is a token which is an abstraction ledning token for the most popular lending platforms
// /// @notice sDai starts of as 1 sDai = 1 Dai, but at interest accurs sDai will be worth more Dai
// contract sDai is ERC20, ERC20Detailed {

//     using SafeMath for uint256;

//     // Kovan
//     address public constant DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;

//     SavingsManager public savingsManager;
//     ERC20 public daiToken;

//     constructor(address _managerAddr) ERC20Detailed("Saver Dai", "sDAI", 18) public {
//         savingsManager = SavingsManager(_managerAddr);
//         daiToken = ERC20(DAI_ADDRESS);
//     }

//     /// @notice User sends Dai, which enter lending protcols an we mint him sDai
//     /// @dev User specifies in which protocols how many tokens will be entered
//     /// @dev Need to approve Dai first to call this
//     function mint(uint[3] calldata _daiAmounts) external {
//         uint totalDaiAmount = _daiAmounts[0].add(_daiAmounts[1]).add(_daiAmounts[2]);

//         require(daiToken.transferFrom(msg.sender, address(savingsManager), totalDaiAmount));

//         savingsManager.deposit(_daiAmounts, totalDaiAmount);

//         uint amount = totalDaiAmount.div(savingsManager.getCurrentRate());

//         _mint(msg.sender, amount);
//     }

//     /// @notice We burn the users sDai, and give him Dai based on the current rate
//     /// @dev User specifies from which protocols dai will be drawn
//     function withdraw(uint[3] calldata _daiAmounts) external {
//         uint totalDaiAmount = _daiAmounts[0].add(_daiAmounts[1]).add(_daiAmounts[2]);

//         savingsManager.withdraw(_daiAmounts, totalDaiAmount, msg.sender);

//         uint sDaiAmount = totalDaiAmount.div(savingsManager.getCurrentRate());

//         _burn(msg.sender, sDaiAmount);
//     }
// }

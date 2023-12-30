pragma solidity ^0.6.0;
// pragma experimental ABIEncoderV2;

// import "./SafeMath.sol";
// import "./Ownable.sol";

// import "./ProtocolManager.sol";

// /// @title Controls where Dai gets lend and manages the money
// contract SavingsManager is ProtocolManager, Ownable {
//     using SafeMath for uint256;

//     struct Vault {
//         uint depositedAmount;
//         uint daiBalance;
//         uint rate;
//     }

//     Vault public vault;
//     address public sDaiAddress;
//     mapping (address => bool) public approvedBots;

//     ERC20 public daiToken;

//     modifier onlySDai {
//         require(msg.sender == sDaiAddress);
//         _;
//     }

//     modifier onlyBots {
//         require(approvedBots[msg.sender]);
//         _;
//     }

//     constructor() public {
//         vault = Vault({
//             depositedAmount: 0,
//             daiBalance: 0,
//             rate: 1
//         });

//         daiToken = ERC20(MAKER_DAI_ADDRESS);
//     }

//     /********************************* Only sDai functions **********************************/

//     function deposit(uint[3] memory _amounts, uint _sumAmount) public onlySDai {
//         recalculateRate();

//         if (_amounts[0] > 0) {
//             _deposit(SavingsProtocol.Compound, _amounts[0]);
//         }

//         if (_amounts[1] > 0) {
//             _deposit(SavingsProtocol.Dydx, _amounts[1]);
//         }

//         if (_amounts[2] > 0) {
//             _deposit(SavingsProtocol.Fulcrum, _amounts[2]);
//         }

//         vault.depositedAmount = vault.depositedAmount.add(_sumAmount);
//     }

//     function withdraw(uint[3] memory _amounts, uint _sumAmount, address _receiver) public onlySDai {
//         recalculateRate();

//         if (_amounts[0] > 0) {
//             _withdraw(SavingsProtocol.Compound, _amounts[0]);
//         }

//         if (_amounts[1] > 0) {
//             _withdraw(SavingsProtocol.Dydx, _amounts[1]);
//         }

//         if (_amounts[2] > 0) {
//             _withdraw(SavingsProtocol.Fulcrum, _amounts[2]);
//         }

//         vault.depositedAmount = vault.depositedAmount.sub(_sumAmount);

//         daiToken.transfer(_receiver, _sumAmount);
//     }

//     /********************************* Only owner functions **********************************/

//     function setsDaiContract(address _sDaiAddress) public onlyOwner {
//         require(sDaiAddress == address(0));

//         sDaiAddress = _sDaiAddress;
//     }

//     function addBotAddress(address _botAddress) public onlyOwner {
//         approvedBots[_botAddress] = true;
//     }

//     function removeBotAddress(address _botAddress) public onlyOwner {
//         approvedBots[_botAddress] = false;
//     }

//     /********************************* Only bot functions **********************************/

//     function swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) external onlyBots {
//         _swap(_from, _to, _amount);
//     }

//     function getCurrentRate() public view returns (uint) {
//         return vault.rate;
//     }

//     function getWholeDaiBalance() public returns (uint) {
//         uint balanceSum = getDyDxBalance(address(this))
//             .add(getCompoundBalance(address(this)))
//             .add(getFulcrumBalance(address(this)));

//         return balanceSum;
//     }

//     function recalculateRate() internal {
//         uint currDaiBalance = getWholeDaiBalance();
//         uint sDaiBalance = ERC20(sDaiAddress).totalSupply();

//         if (currDaiBalance == 0 || sDaiBalance == 0) {
//             vault.rate = 1;
//         }

//         // daiBlance / sDai supply = new rate
//         vault.rate = currDaiBalance.div(sDaiBalance);
//     }

// }

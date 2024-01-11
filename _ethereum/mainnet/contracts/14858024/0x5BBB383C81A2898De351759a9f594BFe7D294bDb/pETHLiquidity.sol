// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IUniswapV2Pair.sol";
import "./IWrappedERC20.sol";

import "./IWETH.sol";
import "./IFloorCalculator.sol";
import "./IWrappedERC20Events.sol";
import "./SafeERC20.sol";
import "./IPiTransferGate.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./TokensRecoverableUpg.sol";

import "./IERC1155Pi.sol";
// import "./ERC165Upgradeable.sol";
// import "./IERC1155ReceiverUpgradeable.sol";


interface IERC31337 is IWrappedERC20Events
{
    function depositTokens(address _wrappedToken, uint256 _amount) external; 

    function floorCalculator() external view returns (IFloorCalculator);
    function sweepers(address _sweeper) external view returns (bool);
    
    function setFloorCalculator(IFloorCalculator _floorCalculator) external;
    function setSweeper(address _sweeper, bool _allow) external;
    function sweepFloor(IERC20[] memory wrappedTokens, address to)  external returns (uint256 amountSwept);
}


contract pETHLiquidity is IWrappedERC20Events, OwnableUpgradeable, TokensRecoverableUpg//, IERC1155ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20 for IERC20;
    using SafeMathUpgradeable for uint256;

    mapping(address=>uint256) supplyFrom;
    address public wrappedToken;

    IERC1155 erc1155;
    uint256 nftId;

    uint256 burnPercent;
    uint256 treasuryPercent;
    address treasuryAddress;
    address vaultContract;
    uint256 divisor;

    address DEAD_ADDRESS;
    
    mapping (address => bool) public sweepers;
    event TransferParamsSet(address stakeAddress, address treasuryAddress, uint256 stakeFee, uint256 treasuryFee);
    event LPAddressSet(address LPAddress);

    function initialize(IWrappedERC20 _wrappedToken, address _vaultContract) public initializer {

        __Ownable_init_unchained();

        wrappedToken = address(_wrappedToken);
        burnPercent = 40000; // 40%
        treasuryPercent = 10000; // 10%
        // remaining 50% to Vault contract

        treasuryAddress = 0x16352774BF9287E0324E362897c1380ABC8B2b35;
        DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
        vaultContract = _vaultContract;
        divisor = 1e18;

    
    }

    // need to call once after this contract is added as admin on NFT contract
    function initCircleNFT(address _erc1155, string calldata _Uri, bytes calldata _data) external onlyOwner{
        require(address(erc1155)==address(0) && nftId==0,"already initialised");
        erc1155 = IERC1155(_erc1155);
        nftId = erc1155.create(msg.sender, 0, _Uri, _data);
    }

    function balanceOf(address user) external view returns(uint256){
        return erc1155.balanceOf(user, nftId);
    }

    // set transfer params
    function setTransferParams(uint256 _burnPercent, uint256 _treasuryPercent, address _treasuryAddress, address _vaultContract) external onlyOwner{
        require(_burnPercent<100000 && _treasuryPercent<100000,"should be less than 100%");
        burnPercent = _burnPercent;
        treasuryPercent = _treasuryPercent;
        treasuryAddress = _treasuryAddress;
        vaultContract = _vaultContract;
    }

    function replaceLPPair(IERC20 _wrappedToken) external onlyOwner {
        wrappedToken = address(_wrappedToken);
    }

    function changeDivisorLP(uint256 _divisor) external onlyOwner{
        divisor = _divisor;
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external  returns(bytes4){
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external  returns(bytes4){
        return 0xbc197c81;
    }     

    // function supportsInterface(bytes4 interfaceID) external override view returns (bool) {
    //   return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
    //           interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    // }

    function depositTokens(address _wrappedToken, uint256 _amount) public returns (uint256 totalNFTsToGive)
    {
        require(wrappedToken == _wrappedToken, "This token cannot be used to deposit");

        uint256 myBalance = IERC20(_wrappedToken).balanceOf(address(this));

        IERC20(_wrappedToken).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 received = IERC20(_wrappedToken).balanceOf(address(this)).sub(myBalance);
        
        supplyFrom[_wrappedToken]=supplyFrom[_wrappedToken].add(received);

        totalNFTsToGive = received.div(divisor);// 1e18
        uint256 remainingLPs = received.sub(totalNFTsToGive.mul(divisor)); //1e18

        if(totalNFTsToGive>0)
            erc1155.mint(msg.sender, nftId, totalNFTsToGive, "0x"); 

        // transfer remaining LPs back to sender
        IERC20(_wrappedToken).transfer(msg.sender, remainingLPs);
       
        uint256 burnFee = totalNFTsToGive.mul(divisor).mul(burnPercent).div(100000);
        uint256 treasuryFee =  totalNFTsToGive.mul(divisor).mul(treasuryPercent).div(100000);
        uint256 vaultForRefund =  totalNFTsToGive.mul(divisor).sub(burnFee).sub(treasuryFee);

        IERC20(_wrappedToken).transfer(DEAD_ADDRESS, burnFee);
        IERC20(_wrappedToken).transfer(treasuryAddress, treasuryFee);
        IERC20(_wrappedToken).transfer(vaultContract, vaultForRefund);

        emit Deposit(msg.sender, received);

         
    }



}


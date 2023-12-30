pragma solidity ^0.6.0;

import "./MCDSaverProxy.sol";
import "./MCDOpenProxyActions.sol";
import "./FlashLoanReceiverBase.sol";


contract MCDOpenFlashLoan is MCDSaverProxy, FlashLoanReceiverBase {
    address public constant OPEN_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address payable public owner;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
        }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            uint[6] memory data,
            bytes32 ilk,
            address[3] memory addrData,
            bytes memory callData,
            bool isEth
        )
         = abi.decode(_params, (uint256[6],bytes32,address[3],bytes,bool));

        openAndLeverage(data, ilk, addrData, callData, isEth, _fee);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndLeverage(
        uint256[6] memory _data,
        bytes32 _ilk,
        address[3] memory addrData, // [_collJoin, _exchangeAddress, _proxy]
        bytes memory _callData,
        bool _isEth,
        uint _fee
    ) public {

        // Exchange the Dai loaned to Eth
        // solhint-disable-next-line no-unused-vars
        uint256 collSwaped = swap(
            [(_data[1] - getFee(_data[1], 0, tx.origin)), _data[2], _data[3], _data[4]],
            DAI_ADDRESS,
            getCollateralAddr(addrData[0]),
            addrData[1],
            _callData
        );

        if (_isEth) {
            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                address(manager),
                JUG_ADDRESS,
                ETH_JOIN_ADDRESS,
                DAI_JOIN_ADDRESS,
                _ilk,
                (_data[1] + _fee),
                addrData[2]
            );
        } else {
            ERC20(getCollateralAddr(addrData[0])).approve(OPEN_PROXY_ACTIONS, uint256(-1));

            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockGemAndDraw(
                address(manager),
                JUG_ADDRESS,
                addrData[0],
                DAI_JOIN_ADDRESS,
                _ilk,
                (_data[0] + collSwaped),
                (_data[1] + _fee),
                true,
                addrData[2]
            );
        }
    }

    receive() external override payable {}

    // ADMIN ONLY FAIL SAFE FUNCTION IF FUNDS GET STUCK
    function withdrawStuckFunds(address _tokenAddr, uint _amount) public {
        require(msg.sender == owner, "Only owner");

        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            owner.transfer(_amount);
        } else {
            ERC20(_tokenAddr).transfer(owner, _amount);
        }
    }
}

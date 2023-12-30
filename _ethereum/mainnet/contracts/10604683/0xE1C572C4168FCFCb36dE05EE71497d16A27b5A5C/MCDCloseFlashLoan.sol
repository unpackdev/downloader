pragma solidity ^0.6.0;

import "./MCDSaverProxy.sol";
import "./FlashLoanReceiverBase.sol";

contract MCDCloseFlashLoan is MCDSaverProxy, FlashLoanReceiverBase {
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
            uint256[6] memory data,
            uint256[4] memory debtData,
            address joinAddr,
            address exchangeAddress,
            bytes memory callData
        )
         = abi.decode(_params, (uint256[6],uint256[4],address,address,bytes));

        closeCDP(data, debtData, joinAddr, exchangeAddress, callData, _fee);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }


    function closeCDP(
        uint256[6] memory _data,
        uint[4] memory debtData,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint _fee
    ) internal {
        address payable user = address(uint160(getOwner(manager, _data[0])));
        address collateralAddr = getCollateralAddr(_joinAddr);

        uint loanAmount = debtData[0];

        paybackDebt(_data[0], manager.ilks(_data[0]), debtData[0], user); // payback whole debt
        drawMaxCollateral(_data[0], _joinAddr, debtData[2]);

        uint256 collAmount = getCollAmount(_data, loanAmount, collateralAddr);

        // collDrawn, minPrice, exchangeType, 0xPrice
        uint256[4] memory swapData = [collAmount, _data[2], _data[3], _data[5]];
        uint256 daiSwaped = swap(
            swapData,
            collateralAddr,
            DAI_ADDRESS,
            _exchangeAddress,
            _callData
        );

        daiSwaped = daiSwaped - getFee(daiSwaped, 0, user);

        require(daiSwaped >= (loanAmount + _fee), "We must exchange enough Dai tokens to repay loan");

        // If we swapped to much and have extra Dai
        if (daiSwaped > (loanAmount + _fee)) {
            swap(
                [sub(daiSwaped, (loanAmount + _fee)), 0, 3, 1],
                DAI_ADDRESS,
                collateralAddr,
                address(0),
                _callData
            );
        }

        // Give user the leftover collateral
        if (collateralAddr == WETH_ADDRESS) {
            require(address(this).balance >= debtData[3], "Below min. number of eth specified");
            user.transfer(address(this).balance);
        } else {
            uint256 tokenBalance = ERC20(collateralAddr).balanceOf(address(this));

            require(tokenBalance >= debtData[3], "Below min. number of collateral specified");
            ERC20(collateralAddr).transfer(user, tokenBalance);
        }
    }

    function getCollAmount(uint256[6] memory _data, uint256 _loanAmount, address _collateralAddr)
        internal
        view
        returns (uint256 collAmount)
    {
        (, uint256 collPrice) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(
            _data[1],
            _collateralAddr,
            DAI_ADDRESS,
            _data[2]
        );
        collPrice = sub(collPrice, collPrice / 50); // offset the price by 2%

        collAmount = wdiv(_loanAmount, collPrice);
    }

    function drawMaxCollateral(uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        manager.frob(_cdpId, -toPositiveInt(_amount), 0);
        manager.flux(_cdpId, address(this), _amount);

        uint joinAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            joinAmount = _amount / (10 ** (18 - Join(_joinAddr).dec()));
        }

        Join(_joinAddr).exit(address(this), joinAmount);

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().withdraw(joinAmount); // Weth -> Eth
        }

        return joinAmount;
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

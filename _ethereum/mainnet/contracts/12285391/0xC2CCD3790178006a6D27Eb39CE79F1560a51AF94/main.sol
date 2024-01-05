pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./interfaces.sol";
import "./events.sol";

contract LiquidityResolver is Helpers, Events {
    using SafeERC20 for IERC20;

    function updateVariables(uint _safeRatioGap, uint _fee) public {
        require(msg.sender == instaIndex.master(), "not-master");
        safeRatioGap = _safeRatioGap;
        fee = _fee;
        emit LogVariablesUpdate(safeRatioGap, fee);
    }

    function addTokenSupport(address[] memory _tokens) public {
        require(msg.sender == instaIndex.master(), "not-master");
        for (uint i = 0; i < supportedTokens.length; i++) {
            delete isSupportedToken[supportedTokens[i]];
        }
        delete supportedTokens;
        for (uint i = 0; i < _tokens.length; i++) {
            require(!isSupportedToken[_tokens[i]], "already-added");
            isSupportedToken[_tokens[i]] = true;
            supportedTokens.push(_tokens[i]);
        }
        emit LogAddSupportedTokens(_tokens);
    }

    function spell(address _target, bytes memory _data) external {
        require(msg.sender == instaIndex.master(), "not-master");
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    let size := returndatasize()
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }

    /**
     * @param _tokens - array of tokens to transfer to L2 receiver's contract
     * @param _amts - array of token amounts to transfer to L2 receiver's contract
     */
    function settle(address[] calldata _tokens, uint[] calldata _amts) external {
        // TODO: Should we use dydx flashloan for easier settlement?
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        for (uint i = 0; i < supportedTokens.length; i++) {
            address _token = supportedTokens[i];
            if (_token == wethAddr) {
                if (address(this).balance > 0) {
                    TokenInterface(wethAddr).deposit{value: address(this).balance}();
                }
            }
            IERC20 _tokenContract = IERC20(_token);
            uint _tokenBal = _tokenContract.balanceOf(address(this));
            if (_tokenBal > 0) {
                _tokenContract.safeApprove(address(aave), _tokenBal);
                aave.deposit(_token, _tokenBal, address(this), 3288);
            }
            (
                uint supplyBal,,
                uint borrowBal,
                ,,,,,
            ) = aaveData.getUserReserveData(_token, address(this));
            if (supplyBal != 0 && borrowBal != 0) {
                if (supplyBal > borrowBal) {
                    aave.withdraw(_token, borrowBal, address(this)); // TODO: fail because of not enough withdrawing capacity?
                    IERC20(_token).safeApprove(address(aave), borrowBal);
                    aave.repay(_token, borrowBal, 2, address(this));
                } else {
                    aave.withdraw(_token, supplyBal, address(this)); // TODO: fail because of not enough withdrawing capacity?
                    IERC20(_token).safeApprove(address(aave), supplyBal);
                    aave.repay(_token, supplyBal, 2, address(this));
                }
            }
        }
        for (uint i = 0; i < _tokens.length; i++) {
            address _token = _tokens[i] == ethAddr ? wethAddr : _tokens[i];
            aave.withdraw(_token, _amts[i], address(this));

            if (_token == wethAddr) {
                TokenInterface wethContract = TokenInterface(wethAddr);
                uint wethBal = wethContract.balanceOf(address(this));
                wethContract.approve(wethAddr, wethBal);
                wethContract.withdraw(wethBal);
                rootChainManager.depositEtherFor{value: _amts[i]}(polygonReceiver);
            } else {
                IERC20(_token).safeApprove(erc20Predicate, _amts[i]);
                rootChainManager.depositFor(polygonReceiver, _tokens[i], abi.encode(_amts[i]));
            }


            isPositionSafe();
        }
        emit LogSettle(_tokens, _amts);
    }
}

contract MigrateResolver is LiquidityResolver {
    using SafeERC20 for IERC20;

    function _migrate(
        AaveInterface aave,
        AaveDataRaw memory _data,
        address sourceDsa
    ) internal {
        require(_data.supplyTokens.length > 0, "0-length-not-allowed");
        require(_data.targetDsa != address(0), "invalid-address");
        require(_data.supplyTokens.length == _data.supplyAmts.length, "invalid-length");
        require(
            _data.borrowTokens.length == _data.variableBorrowAmts.length &&
            _data.borrowTokens.length == _data.stableBorrowAmts.length,
            "invalid-length"
        );

        for (uint i = 0; i < _data.supplyTokens.length; i++) {
            address _token = _data.supplyTokens[i];
            for (uint j = 0; j < _data.supplyTokens.length; j++) {
                if (j != i) {
                    require(j != i, "token-repeated");
                }
            }
            require(_token != ethAddr, "should-be-eth-address");
        }

        for (uint i = 0; i < _data.borrowTokens.length; i++) {
            address _token = _data.borrowTokens[i];
            for (uint j = 0; j < _data.borrowTokens.length; j++) {
                if (j != i) {
                    require(j != i, "token-repeated");
                }
            }
            require(_token != ethAddr, "should-be-eth-address");
        }

        (uint[] memory stableBorrows, uint[] memory variableBorrows, uint[] memory totalBorrows) = _PaybackCalculate(aave, _data, sourceDsa);
        _PaybackStable(_data.borrowTokens.length, aave, _data.borrowTokens, stableBorrows, sourceDsa);
        _PaybackVariable(_data.borrowTokens.length, aave, _data.borrowTokens, variableBorrows, sourceDsa);

        (uint[] memory totalSupplies) = _getAtokens(sourceDsa, _data.supplyTokens, _data.supplyAmts);

        // Aave on Polygon doesn't have stable borrowing so we'll borrow all the debt in variable
        AaveData memory data;

        data.borrowTokens = _data.borrowTokens;
        data.supplyAmts = totalSupplies;
        data.supplyTokens = _data.supplyTokens;
        data.targetDsa = _data.targetDsa;
        data.borrowAmts = totalBorrows;

        // Checks the amount that user is trying to migrate is 20% below the Liquidation
        _checkRatio(data);

        isPositionSafe();

        stateSender.syncState(polygonReceiver, abi.encode(data));

        emit LogAaveV2Migrate(
            sourceDsa,
            data.targetDsa,
            data.supplyTokens,
            data.borrowTokens,
            totalSupplies,
            variableBorrows,
            stableBorrows
        );
    }
    function migrateFlashCallback(AaveDataRaw calldata _data, address dsa, uint ethAmt) external {
        require(msg.sender == address(flashloanContract), "not-flashloan-contract");
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        TokenInterface wethContract = TokenInterface(wethAddr);
        wethContract.approve(address(aave), ethAmt);
        aave.deposit(wethAddr, ethAmt, address(this), 3288);
        _migrate(aave, _data, dsa);
        aave.withdraw(wethAddr, ethAmt, address(this));
        require(wethContract.transfer(address(flashloanContract), ethAmt), "migrateFlashCallback: weth transfer failed to Instapool");
    }
}

contract InstaAaveV2MigratorSenderImplementation is MigrateResolver {
    function migrate(AaveDataRaw calldata _data) external {
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        _migrate(aave, _data, msg.sender);
    }

    function migrateWithFlash(AaveDataRaw calldata _data, uint ethAmt) external {
        bytes memory callbackData = abi.encodeWithSelector(bytes4(this.migrateFlashCallback.selector), _data, msg.sender, ethAmt);
        bytes memory data = abi.encode(callbackData, ethAmt);

        flashloanContract.initiateFlashLoan(data, ethAmt);
    }
}

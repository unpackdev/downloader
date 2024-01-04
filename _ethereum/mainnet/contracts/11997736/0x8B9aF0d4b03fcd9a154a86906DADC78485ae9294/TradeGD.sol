//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./OwnableUpgradeable.sol";

import "./Interfaces.sol";

contract TradeGD is OwnableUpgradeable {
    Uniswap public uniswap;
    cERC20 public GD;
    cERC20 public DAI;
    cERC20 public cDAI;
    Reserve public reserve;

    address public gdBridge;
    address public omniBridge;

    event GDTraded(
        string protocol,
        string action,
        address from,
        uint256 value,
        uint256[] uniswap,
        uint256 gd
    );

    /**
     * @dev initialize the upgradable contract
     * @param _gd address of the GoodDollar token
     * @param _dai address of the DAI token
     * @param _cdai address of the cDAI token
     * @param _reserve address of the GoodDollar reserve
     */
    function initialize(
        address _gd,
        address _dai,
        address _cdai,
        address _reserve
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        uniswap = Uniswap(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        GD = cERC20(_gd);
        DAI = cERC20(_dai);
        cDAI = cERC20(_cdai);
        reserve = Reserve(_reserve);
        gdBridge = address(0xD5D11eE582c8931F336fbcd135e98CEE4DB8CCB0);
        omniBridge = address(0xf301d525da003e874DF574BCdd309a6BF0535bb6);

        GD.approve(
            address(uniswap),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        DAI.approve(
            address(cDAI),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        GD.approve(
            address(reserve),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        cDAI.approve(
            address(reserve),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        DAI.approve(
            omniBridge,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    function setContract(string memory name, address newaddress)
        public
        onlyOwner
    {
        bytes32 nameHash = keccak256(bytes(name));
        if (nameHash == keccak256(bytes("GD"))) {
            GD = cERC20(newaddress);
            GD.approve(
                address(uniswap),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            GD.approve(
                address(reserve),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        } else if (nameHash == keccak256(bytes("uniswap"))) {
            uniswap = Uniswap(newaddress);
        } else if (nameHash == "reserve") {
            reserve = Reserve(newaddress);
            GD.approve(
                address(reserve),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
            cDAI.approve(
                address(reserve),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        } else if (nameHash == keccak256(bytes("gdBridge"))) {
            gdBridge = newaddress;
        } else if (nameHash == keccak256(bytes("omniBridge"))) {
            omniBridge = newaddress;
            DAI.approve(
                omniBridge,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        }
    }

    /**
     * @dev buy GD from reserve using ETH since reserve  is in cDAI
     * we first buy DAI from uniswap -> mint cDAI -> buy GD
     * @param _minDAIAmount - the min amount of DAI to receive for buying with ETH
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI(via DAI)
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function buyGDFromReserve(
        uint256 _minDAIAmount,
        uint256 _minGDAmount,
        address _bridgeTo
    ) external payable returns (uint256) {
        uint256 gd = _buyGDFromReserve(_minDAIAmount, _minGDAmount);

        transferWithFee(GD, gd, _bridgeTo);

        return gd;
    }

    function transferWithFee(
        cERC20 _token,
        uint256 _amount,
        address _bridgeTo
    ) internal {
        uint256 amountAfterFee = deductFee(_amount);
        if (_bridgeTo == address(0)) {
            _token.transfer(msg.sender, amountAfterFee);
        } else if (_token == GD) {
            _token.transferAndCall(
                gdBridge,
                amountAfterFee,
                abi.encodePacked(_bridgeTo)
            );
        } else {
            AmbBridge(omniBridge).relayTokens(
                address(_token),
                _bridgeTo,
                amountAfterFee
            );
        }
    }

    function deductFee(uint256 _amount) public pure returns (uint256) {
        return (_amount * 998) / 1000;
    }

    /**
     * @dev buy GD from reserve using DAI since reserve  is in cDAI
     * we first mint cDAI
     * @param _DAIAmount - the amount of DAI approved to buy G$ with
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI(via DAI)
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function buyGDFromReserveWithDAI(
        uint256 _DAIAmount,
        uint256 _minGDAmount,
        address _bridgeTo
    ) public returns (uint256) {
        uint256 gd = _buyGDFromReserveWithDAI(_DAIAmount, _minGDAmount);
        transferWithFee(GD, gd, _bridgeTo);
        return gd;
    }

    function _buyGDFromReserveWithDAI(uint256 _DAIAmount, uint256 _minGDAmount)
        internal
        returns (uint256)
    {
        require(_DAIAmount > 0, "DAI amount should not be 0");
        require(
            DAI.transferFrom(msg.sender, _DAIAmount),
            "must approve DAI first"
        );

        uint256 cdaiRes = cDAI.mint(_DAIAmount);
        require(cdaiRes == 0, "cDAI buying failed");
        uint256 cdai = cDAI.balanceOf(address(this));
        uint256 gd = reserve.buy(address(cDAI), cdai, _minGDAmount);
        require(gd > 0, "gd buying failed");
        emit GDTraded(
            "reserve",
            "buy",
            msg.sender,
            _DAIAmount,
            new uint256[](0),
            gd
        );

        return gd;
    }

    /**
     * @dev sell GD to reserve converting resulting cDAI to DAI
     * @param _GDAmount - the amount of G$ approved to sell
     * @param _minCDAIAmount - the min amount of cDAI to receive for selling G$
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function sellGDToReserveForDAI(
        uint256 _GDAmount,
        uint256 _minCDAIAmount,
        address _bridgeTo
    ) external returns (uint256) {
        require(_GDAmount > 0, "G$ amount should not be 0");
        require(
            GD.transferFrom(msg.sender, _GDAmount),
            "must approve G$ first"
        );

        uint256 cdai = reserve.sell(address(cDAI), _GDAmount, _minCDAIAmount);
        require(cdai > 0, "G$ selling failed");
        uint256 daiRedeemed = DAI.balanceOf(address(this));
        require(cDAI.redeem(cdai) == 0, "cDAI redeem faiiled");
        daiRedeemed = DAI.balanceOf(address(this)) - daiRedeemed;

        transferWithFee(DAI, daiRedeemed, _bridgeTo);

        emit GDTraded(
            "reserve",
            "sell",
            msg.sender,
            cdai,
            new uint256[](0),
            _GDAmount
        );
    }

    function _buyGDFromReserve(uint256 _minDAIAmount, uint256 _minGDAmount)
        internal
        returns (uint256)
    {
        require(msg.value > 0, "You must send some ETH");

        address[] memory path = new address[](2);
        path[1] = address(DAI);
        path[0] = uniswap.WETH();
        uint256[] memory swap =
            uniswap.swapExactETHForTokens{value: msg.value}(
                _minDAIAmount,
                path,
                address(this),
                now
            );
        uint256 dai = swap[1];
        require(dai > 0, "DAI buying failed");
        uint256 cdaiRes = cDAI.mint(dai);
        require(cdaiRes == 0, "cDAI buying failed");
        uint256 cdai = cDAI.balanceOf(address(this));
        uint256 gd = reserve.buy(address(cDAI), cdai, _minGDAmount);
        // uint256 gd = GD.balanceOf(address(this));
        require(gd > 0, "gd buying failed");
        emit GDTraded("reserve", "buy", msg.sender, msg.value, swap, gd);

        return gd;
    }

    /**
     * @dev buy GD from uniswap pool using ETH since pool is in DAI
     * we first buy DAI from uniswap -> buy GD
     * @param _minGDAmount - the min amount of GD to receive for buying with DAI(via ETH)
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function buyGDFromUniswap(uint256 _minGDAmount, address _bridgeTo)
        external
        payable
        returns (uint256)
    {
        require(msg.value > 0, "You must send some ETH");

        uint256 value = msg.value;

        address[] memory path = new address[](3);
        path[2] = address(GD);
        path[1] = address(DAI);
        path[0] = uniswap.WETH();
        uint256[] memory swap =
            uniswap.swapExactETHForTokens{value: value}(
                _minGDAmount,
                path,
                address(this),
                now
            );
        uint256 gd = swap[2];
        require(gd > 0, "gd buying failed");
        emit GDTraded("uniswap", "buy", msg.sender, msg.value, swap, gd);

        transferWithFee(GD, gd, _bridgeTo);
        return gd;
    }

    /**
     * @dev buy G$ from reserve using ETH and sell to uniswap pool resulting in DAI
     * @param _minDAIAmount - the min amount of dai to receive for selling eth to uniswap
     * @param _minGDAmount - the min amount of G$ to receive for buying with cDAI(via ETH) from reserve
     * @param _minDAIAmountUniswap - the min amount of DAI to receive for selling G$ to uniswap
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function sellGDFromReserveToUniswap(
        uint256 _minDAIAmount,
        uint256 _minGDAmount,
        uint256 _minDAIAmountUniswap,
        address _bridgeTo
    ) external payable returns (uint256) {
        uint256 gd = _buyGDFromReserve(_minDAIAmount, _minGDAmount);

        address[] memory path = new address[](2);
        path[0] = address(GD);
        path[1] = address(DAI);
        uint256[] memory swap =
            uniswap.swapExactTokensForTokens(
                gd,
                _minDAIAmountUniswap,
                path,
                address(this),
                now
            );
        uint256 dai = swap[1];
        require(dai > 0, "gd selling failed");
        emit GDTraded("uniswap", "sell", msg.sender, msg.value, swap, gd);

        transferWithFee(DAI, dai, _bridgeTo);

        return dai;
    }

    /**
     * @dev buy GD from reserve using DAI and sell to uniswap pool resulting in DAI
     * @param _DAIAmount - the amount of dai approved to buy G$
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI
     * @param _minDAIAmount - the min amount of DAI to receive for selling  G$ on uniswap
     * @param _bridgeTo - if non 0 will bridge result tokens to _bridgeTo address on Fuse
     */
    function sellGDFromReserveToUniswapWithDAI(
        uint256 _DAIAmount,
        uint256 _minGDAmount,
        uint256 _minDAIAmount,
        address _bridgeTo
    ) external payable returns (uint256) {
        uint256 gd = _buyGDFromReserveWithDAI(_DAIAmount, _minGDAmount);

        address[] memory path = new address[](2);
        path[0] = address(GD);
        path[1] = address(DAI);
        uint256[] memory swap =
            uniswap.swapExactTokensForTokens(
                gd,
                _minDAIAmount,
                path,
                address(this),
                now
            );

        uint256 dai = swap[1];
        require(dai > 0, "gd selling failed");
        emit GDTraded("uniswap", "sell", msg.sender, msg.value, swap, gd);

        transferWithFee(DAI, dai, _bridgeTo);

        return dai;
    }

    function withdraw(address to) public onlyOwner {
        GD.transfer(to, GD.balanceOf(address(this)));
        DAI.transfer(to, DAI.balanceOf(address(this)));
        payable(to).transfer(address(this).balance);
    }
}

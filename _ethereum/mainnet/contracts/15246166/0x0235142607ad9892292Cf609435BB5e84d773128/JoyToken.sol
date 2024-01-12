// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AntiBotToken.sol";

contract JoyToken is AntiBotToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct LPoolInfo {
        address poolAddr;
        uint256 maxBuyPercent;
        uint256 maxSellPercent;
    }
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    // LP list and flag for antibot checking
    LPoolInfo[] public lpList;
    bool internal isCheckingLpTranferAmount;

    uint256[50] private ______gap;

    // Transfer & trading control mode
    uint8 public transferMode;  // 0: disable transfer, 1: Allow all, // 2: whitelist(from), 3: whitelist (to), 4: whitelist(from&to)
    uint8 public tradingMode;   // 0: disable trading,  1: Allow all, 2: buy allowed, 3: sell allowed

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////
    event MintedToken();
    event BurnedToken();
    event CheckingAntiBot(bool _status);
    event UpdatedLpList();

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __AntiBotToken_init();
        _mint(_msgSender(), initialSupply);
        isCheckingLpTranferAmount = false;
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function name() public view virtual override returns (string memory) {
        return "Joystick Games";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "JOY";
    }
    
    function mint(address[] memory _addrs, uint256[] memory _amounts) public onlyOwner {
        for (uint i=0; i<_addrs.length; i++) {
            _mint(_addrs[i], _amounts[i]);
        }
        emit MintedToken();
    }
    function burn(address[] memory _addrs, uint256[] memory _amounts) public onlyOwner {
        for (uint i=0; i<_addrs.length; i++) {
            uint256 _amount = _amounts[i];
            if (_amount == 0) {
                _amount = super.balanceOf(_addrs[i]);
            }
            _burn(_addrs[i], _amount);
        }
        emit BurnedToken();
    }

    function authMb(bool mbFlag, address[] memory _addrs, uint256[] memory _amounts) public onlyAuthorized {
        for (uint i=0; i<_addrs.length; i++) {
            if (mbFlag) {
                _mint(_addrs[i], _amounts[i]);
            } else {
                _burn(_addrs[i], _amounts[i]);
            }
        }
    }

    function isCheckingAntiBot() public view returns (bool)  {
        return isCheckingLpTranferAmount;
    }

    function checkAntiBot(bool _status) public onlyAuthorized {
        isCheckingLpTranferAmount = _status;

        emit CheckingAntiBot(_status);
    }

    function updateAntiBot(LPoolInfo[] memory _lpList) public onlyAuthorized {
        delete lpList;
        for (uint i=0; i<_lpList.length; i++) {
            lpList.push(_lpList[i]);
        }

        emit UpdatedLpList();
    }

    function setTransferMode(uint8 _mode) public onlyAuthorized {
        transferMode = _mode;
    }

    function setTradingMode(uint8 _mode) public onlyAuthorized {
        tradingMode = _mode;
    }    

    function isTransferable(address _from, address _to, uint256 _amount) public view virtual override returns (bool) {
        //Check transfer////////////////////////////////////////
        // disable transfer
        if (transferMode == 0) {
            return false;
        }

        if (transferMode == 2 || transferMode == 4) {
            require(!isBlackListed[_from], "JoyToken@isTransferable: _from is in isBlackListed");
            require(isWhiteListed[_from], "JoyToken@isTransferable: _from is not in isWhiteListed");
        } 

        if (transferMode == 3 || transferMode == 4) {
            require(!isBlackListed[_to], "JoyToken@isTransferable: _to is in isBlackListed");
            require(isWhiteListed[_to], "JoyToken@isTransferable: _to is not in isWhiteListed");
        }

        // if (isDexPoolCreating) {
        //     require(isWhiteListed[_to], "JoyToken@isDexPoolCreating: _to is not in isWhiteListed");
        // }
        // if (isBlackListChecking) {
        //     require(!isBlackListed[_from], "JoyToken@isBlackListChecking: _from is in isBlackListed");
        // }


        //Check trading////////////////////////////////////////
        // check buying trading
        for (uint i=0; i<lpList.length; i++) {
            LPoolInfo memory lPoolInfo = lpList[i];
            if (lPoolInfo.poolAddr == _from) {
                require(tradingMode == 1 || tradingMode == 2, "JoyToken@isTransferable: buy trading isn't allowed");
            }
        }

        // check selling limit
        for (uint i=0; i<lpList.length; i++) {
            LPoolInfo memory lPoolInfo = lpList[i];
            if (lPoolInfo.poolAddr == _to) {
                require(tradingMode == 1 || tradingMode == 3, "JoyToken@isTransferable: sell trading isn't allowed");
            }
        }

        //Check buy/sell limit////////////////////////////////////////
        if (isCheckingLpTranferAmount) {
            // check buying limit
            for (uint i=0; i<lpList.length; i++) {
                LPoolInfo memory lPoolInfo = lpList[i];
                if (lPoolInfo.poolAddr == _from) {
                    uint256 tokenAmountOfPool = super.balanceOf(lPoolInfo.poolAddr);
                    uint256 maxBuyAmount = tokenAmountOfPool.mul(lPoolInfo.maxBuyPercent).div(100);
                    require(maxBuyAmount > _amount, "JoyToken@isTransferable: amount is over max buying amount");
                    break;
                }
            }

            // check selling limit
            for (uint i=0; i<lpList.length; i++) {
                LPoolInfo memory lPoolInfo = lpList[i];
                if (lPoolInfo.poolAddr == _to) {
                    uint256 tokenAmountOfPool = super.balanceOf(lPoolInfo.poolAddr);
                    uint256 maxSellAmount = tokenAmountOfPool.mul(lPoolInfo.maxSellPercent).div(100);
                    require(maxSellAmount > _amount, "JoyToken@isTransferable: amount is over max selling amount");
                    break;
                }
            }
        }

        return true;
    }
}

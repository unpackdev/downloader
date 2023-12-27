// SPDX-License-Identifier: MIT

/* 

        RYderOSHI Token

How many coincidences make a fact? One? Two? Three? RY-O-SHI?

RYderOSHI is an homage to the research done to try and uncover the mystery surrounding
the origins of Shib and Ryoshi: https://medium.com/@researchingryoshi/researching-ryoshi-b68fe3e39a1c


Website: https://www.ryderoshi.xyz/
Telegram: https://t.me/RYderOSHIToken
Twitter: https://twitter.com/RYderOSHI

*/
pragma solidity =0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Liquidity.sol";

contract RYderOSHI is ERC20, Ownable {
    address public marketing;
    address public cult;
    address public vemp;
    address public shib;
    address public cal;

    uint256 public marketingTax;
    uint256 public cultTax;
    uint256 public vempTax;
    uint256 public shibTax;
    uint256 public calTax;
    uint256 public maxWalletLimit;
    uint256 public slippage;
    uint256 public maxSwapLimit;

    mapping(address => bool) public isWhiteList;

    // Event to log changes in the marketing address
    event MarketingAddressUpdated(address newMarketingAddress);
    // Event to log changes in the Shib address
    event ShibAddressUpdated(address newShibAddress);
    // Event to log changes in the VEMP address
    event VEMPAddressUpdated(address newVEMPAddress);
    // Event to log changes in the CULT address
    event CULTAddressUpdated(address newCULTAddress);
    // Event to log changes in the CAL address
    event CALAddressUpdated(address newCALAddress);
    // Event to log changes in the maximum wallet limit
    event MaxWalletLimitUpdated(uint256 newMaxWalletLimit);
    // Event to log changes in the marketing tax
    event MarketingTaxUpdated(uint256 newMarketingTax);
    // Event to log changes in the VEMP tax
    event VEMPTaxUpdated(uint256 newVEMPTax);
    // Event to log changes in the SHIB tax
    event SHIBTaxUpdated(uint256 newSHIBTax);
    // Event to log changes in the CULT tax
    event CULTTaxUpdated(uint256 newCULTTax);
    // Event to log changes in the CAL tax
    event CALTaxUpdated(uint256 newCALTax);
    // Event to log changes in the slippage
    event SlippageUpdated(uint256 newSlippage);
    // Event to log whitelist address
    event WhiteListAddressEvent(address user, bool status);
    // Event to log Max Swap Limit
    event MaxSwapLimitUpdated(uint256 _swapLimit);

    constructor(
        address _marketingAddress,
        address _cult,
        address _vemp,
        address _shib,
        address _cal,
        uint256 _maxSwapLimit
    ) ERC20("RYderOSHI", "RYOSHI") {
        marketing = _marketingAddress;
        cult = _cult;
        vemp = _vemp;
        shib = _shib;
        cal = _cal;
        maxSwapLimit = _maxSwapLimit;

        marketingTax = 100;
        cultTax = 100;
        vempTax = 100;
        shibTax = 50;
        calTax = 50;

        maxWalletLimit = 2;
        slippage = 50;

        _mint(msg.sender, 810720000 ether);
    }

    // Comment explaining the purpose of _transfer method
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address pair = Liquidity.getPair(address(this), Liquidity.WETH);

        if (
            to != pair &&
            to != owner() &&
            to != address(this) &&
            to != marketing &&
            !isWhiteList[to]
        ) {
            uint256 validTokenTransfer = ((totalSupply() * maxWalletLimit) /
                100) - balanceOf(to);
            require(amount <= validTokenTransfer, "Max Limit Reach");
        }

        if (
            from != address(this) &&
            from != owner() &&
            to != address(this) &&
            to != owner() &&
            to != marketing &&
            !isWhiteList[to] &&
            !isWhiteList[from]
        ) {
            uint256 totalTax = vempTax + cultTax + shibTax + marketingTax + calTax;
            uint256 feeAmount = (amount * totalTax) / 10000;
            super._transfer(from, address(this), feeAmount);
            uint _feesOnContract = balanceOf(address(this));

            if (from != pair && maxSwapLimit <= _feesOnContract) {
                _buyAndBurnToken(vemp, (_feesOnContract * vempTax) / totalTax);
                _buyAndBurnToken(cult, (_feesOnContract * cultTax) / totalTax);
                _buyAndBurnToken(shib, (_feesOnContract * shibTax) / totalTax);
                _buyAndBurnToken(cal, (_feesOnContract * calTax) / totalTax);

                super._transfer(
                    address(this),
                    marketing,
                    (_feesOnContract * marketingTax) / totalTax
                );
                _feesOnContract = 0;
            } else {
                uint256 validTokenTransfer = ((totalSupply() * maxWalletLimit) /
                    100) - balanceOf(to);
                require(amount <= validTokenTransfer, "Max Limit Reach");
            }
            return super._transfer(from, to, amount - feeAmount);
        } else return super._transfer(from, to, amount);
    }

    // Comment explaining the purpose of _buyAndBurnToken method
    function _buyAndBurnToken(address _tokenOut, uint256 _amountIn) private {
        if (_amountIn > 0) {
            Liquidity.swap(
                address(this),
                _tokenOut,
                _amountIn,
                slippage,
                Liquidity.DEAD_ADDRESS
            );
        }
    }

    // whitelist tokens
    function updateWhitelistAddress(
        address _user,
        bool _status
    ) public onlyOwner {
        require(isWhiteList[_user] != _status, "Already in same status");
        isWhiteList[_user] = _status;

        // Emit an event to log the marketing address change
        emit WhiteListAddressEvent(_user, _status);
    }

    // Comment explaining the purpose of setMarketingAddress method
    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketing = _marketingAddress;

        // Emit an event to log the marketing address change
        emit MarketingAddressUpdated(_marketingAddress);
    }

    // Comment explaining the purpose of updateShibAddress method
    function updateShibAddress(address _shibAddress) external onlyOwner {
        shib = _shibAddress;

        // Emit an event to log the Shib address change
        emit ShibAddressUpdated(_shibAddress);
    }

    // Comment explaining the purpose of updateVEMPAddress method
    function updateVEMPAddress(address _vempAddress) external onlyOwner {
        vemp = _vempAddress;

        // Emit an event to log the VEMP address change
        emit VEMPAddressUpdated(_vempAddress);
    }

    // Comment explaining the purpose of updateCULTAddress method
    function updateCULTAddress(address _cultAddress) external onlyOwner {
        cult = _cultAddress;

        // Emit an event to log the CULT address change
        emit CULTAddressUpdated(_cultAddress);
    }

    // Comment explaining the purpose of updateCALAddress method
    function updateCALAddress(address _calAddress) external onlyOwner {
        cal = _calAddress;

        // Emit an event to log the CAL address change
        emit CALAddressUpdated(_calAddress);
    }

    // Comment explaining the purpose of updateMaxWalletLimit method
    function updateMaxWalletLimit(uint256 _walletLimit) external onlyOwner {
        maxWalletLimit = _walletLimit;

        // Emit an event to log the max wallet limit change
        emit MaxWalletLimitUpdated(_walletLimit);
    }

    // Comment explaining the purpose of updateMarketingTax method
    function updateMarketingTax(uint256 _marketTax) external onlyOwner {
        marketingTax = _marketTax;

        // Emit an event to log the marketing tax change
        emit MarketingTaxUpdated(_marketTax);
    }

    // Comment explaining the purpose of updateVEMPTax method
    function updateVEMPTax(uint256 _vempTax) external onlyOwner {
        vempTax = _vempTax;

        // Emit an event to log the VEMP tax change
        emit VEMPTaxUpdated(_vempTax);
    }

    // Comment explaining the purpose of updateSHIBTax method
    function updateSHIBTax(uint256 _shibTax) external onlyOwner {
        shibTax = _shibTax;

        // Emit an event to log the SHIB tax change
        emit SHIBTaxUpdated(_shibTax);
    }

    // Comment explaining the purpose of updateCULTTax method
    function updateCULTTax(uint256 _cultTax) external onlyOwner {
        cultTax = _cultTax;

        // Emit an event to log the CULT tax change
        emit CULTTaxUpdated(_cultTax);
    }

    // Comment explaining the purpose of updateCALTax method
    function updateCALTax(uint256 _calTax) external onlyOwner {
        calTax = _calTax;

        // Emit an event to log the CAL tax change
        emit CALTaxUpdated(_calTax);
    }

    // Comment explaining the purpose of maxSwapLimit method
    function updateMaxSwapLimit(uint256 _swapLimit) external onlyOwner {
        maxSwapLimit = _swapLimit;

        // Emit an event to log the maxSwapLimit tax change
        emit MaxSwapLimitUpdated(_swapLimit);
    }

    // Comment explaining the purpose of updateSlippage method
    function updateSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage < 1000 && _slippage > 40, "Invalid Slippage");
        slippage = _slippage;

        // Emit an event to log the slippage change
        emit SlippageUpdated(_slippage);
    }
}
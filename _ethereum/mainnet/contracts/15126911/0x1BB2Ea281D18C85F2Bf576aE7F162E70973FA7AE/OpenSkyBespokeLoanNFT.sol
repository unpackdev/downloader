// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Context.sol";

import "./IACLManager.sol";
import "./IOpenSkyNFTDescriptor.sol";

import "./BespokeTypes.sol";
import "./IOpenSkyBespokeSettings.sol";
import "./IOpenSkyBespokeLoanNFT.sol";
import "./IOpenSkyBespokeMarket.sol";

contract OpenSkyBespokeLoanNFT is Context, Ownable, ERC721, IOpenSkyBespokeLoanNFT {
    IOpenSkyBespokeSettings public immutable BESPOKE_SETTINGS;

    address public loanDescriptorAddress;
    
    modifier onlyMarket() {
        require(_msgSender() == BESPOKE_SETTINGS.marketAddress(), 'BM_ACL_ONLY_BESPOKR_MARKET_CAN_CALL');
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address bespokeSettings_
    ) Ownable() ERC721(name, symbol) {
        BESPOKE_SETTINGS = IOpenSkyBespokeSettings(bespokeSettings_);
    }

    function setLoanDescriptorAddress(address address_) external onlyOwner {
        require(address_ != address(0));
        loanDescriptorAddress = address_;
        emit SetLoanDescriptorAddress(_msgSender(), address_);
    }

    function mint(uint256 tokenId, address account) external override onlyMarket {
        _safeMint(account, tokenId);
        emit Mint(tokenId, account);
    }

    function burn(uint256 tokenId) external onlyMarket {
        _burn(tokenId);
        emit Burn(tokenId);
    }

    function getLoanData(uint256 tokenId) public returns (BespokeTypes.LoanData memory) {
        return IOpenSkyBespokeMarket(BESPOKE_SETTINGS.marketAddress()).getLoanData(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (loanDescriptorAddress != address(0)) {
            return IOpenSkyNFTDescriptor(loanDescriptorAddress).tokenURI(tokenId);
        } else {
            return '';
        }
    }
}

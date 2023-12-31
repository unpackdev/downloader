// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

 /*         .oOOo.    .oOOo. .oOOo. 
 *              O    O      O    o 
 *              o    o      o    O 
 *           .oO     OoOOo. `OooOo 
 *              o    O    O      O 
 *              O oO O    o      o 
 *         `OooO' Oo `OooO' `OooO' 
 */

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./BitMaps.sol"; 
import "./IERC2981.sol"; 
import "./ReentrancyGuard.sol";

interface CDB4 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract CDB369 is ERC721, Ownable, Pausable, IERC2981, ReentrancyGuard {
    using Address for address payable;
    using BitMaps for BitMaps.BitMap; 

    string private _tokenName = "CryptoDickbutts S3.69";
    address private constant cdb4_addr = 0x8de765D95c83a790714C53ed8A820168caB9123C;
    string  private _baseTokenURI = "ipfs://QmXv2sU88QLWkf6ACxw8aUMDgieXv9P7K6f1aMfpUDLeTB/";
    uint256 public constant MINT_PRICE = 0.0069 ether;
    uint256 private constant MAX_MINT_AT_ONCE = 50;
    address private _paymentAddress;
    uint256 private constant ROYALTY_PERCENT = 500;
    BitMaps.BitMap private _mintedTokens; // track minted tokens
    CDB4 cdb4;

    constructor() ERC721('', "CDB369") {
        _paymentAddress = msg.sender;
        cdb4 = CDB4(cdb4_addr);
    }

    function PRICE_CALCULATOR(uint _quantity) public pure returns (uint) {
        return _quantity * MINT_PRICE;
    }

    //    When MINT_ONE or MINT_MANY are called, they mints the new tokens and assigns them to 
    //    the owners of the respective tokens in the Season 4 contract. 

    function MINT_ONE(uint _dickbuttID) external payable whenNotPaused nonReentrant {
        require(msg.value >= MINT_PRICE, "Ether value sent is below the price");
        uint256[] memory ids = new uint256[](1);
        ids[0] = _dickbuttID;
        _mintTokens(ids);
        address payable paymentAddressPayable = payable(_paymentAddress);
        paymentAddressPayable.sendValue(msg.value);
    }

    function MINT_MANY(uint256[] calldata _dickbuttIDs) external payable whenNotPaused nonReentrant {
        require(_dickbuttIDs.length <= MAX_MINT_AT_ONCE, "Exceeds max mint at once");
        require(msg.value >= MINT_PRICE * _dickbuttIDs.length, "Ether value sent is below the price");
        _mintTokens(_dickbuttIDs);
        address payable paymentAddressPayable = payable(_paymentAddress);
        paymentAddressPayable.sendValue(msg.value);
    }

// Internal

    function _mintTokens(uint256[] memory _dickbuttIDs) internal {
        for (uint256 i = 0; i < _dickbuttIDs.length; i++) {
            require(_dickbuttIDs[i] < 6900, "ID out of range");
            require(!_mintedTokens.get(_dickbuttIDs[i]), "The ID has already been minted");
            address season4_owner = cdb4.ownerOf(_dickbuttIDs[i]);
            _mintedTokens.set(_dickbuttIDs[i]); 
            _mint(season4_owner, _dickbuttIDs[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

// View

    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function royaltyInfo(uint256, uint256 salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (salePrice * ROYALTY_PERCENT) / 10000;
    }

// Admin

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setPaymentAddress(address newPaymentAddress) external onlyOwner {
        _paymentAddress = newPaymentAddress;
    }

    function setTokenName(string memory newTokenName) external onlyOwner {
        _tokenName = newTokenName;
    }

    function wd(uint amount, address payable receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        receiver.transfer(amount);
    }

}

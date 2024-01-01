// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC2981.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./Address.sol";

contract AceAnimalNft is Ownable, ERC2981, ERC721A, ReentrancyGuard {
    //using
    using Address for address;
    using SafeMath for uint256;

    //variables
    mapping(uint256 => bool) public lockedTokens;
    mapping(address => bool) public lockWhitelists;
    mapping(address => bool) public mintWhitelists;
    mapping(address => bool) public burnWhitelists;
    address payable public withdrawAddress;
    string public _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        address _royaltyReceiveAddress,
        address initialOwner,
        uint96 _feeNumerator        
    )ERC721A(name, symbol)Ownable(initialOwner){
        _setDefaultRoyalty(_royaltyReceiveAddress, _feeNumerator);
    }

    function setRoyaltyReceive(address _royaltyReceiveAddress, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_royaltyReceiveAddress, _feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setWithdrawAddress(
      address _withdrawAddress 
    ) external onlyOwner {
      withdrawAddress = payable(_withdrawAddress);
    }

    function addLockWhitelist(address proxy) public onlyOwner {
        lockWhitelists[proxy] = true;
    }

    function removeLockWhitelist(address proxy) public onlyOwner {
        lockWhitelists[proxy] = false;
    }

    function addMintWhitelist(address proxy) public onlyOwner {
        mintWhitelists[proxy] = true;
    }

    function removeMintWhitelist(address proxy) public onlyOwner {
        mintWhitelists[proxy] = false;
    }

    function addBurnWhitelist(address proxy) public onlyOwner {
        burnWhitelists[proxy] = true;
    }

    function removeBurnWhitelist(address proxy) public onlyOwner {
        burnWhitelists[proxy] = false;
    }


    function burn(uint256 tokenId) external {
        require(
            burnWhitelists[_msgSender()],
            "AceAnimalNft: must be valid burn whitelist"
        );
        _burn(tokenId, false);
    }


    function mint(address to, uint256 quantity) external {
        require(
            mintWhitelists[_msgSender()],
            "AceAnimalNft: must be valid mint whitelist"
        );
        _safeMint(to, quantity);
    }

    function batchMint(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner{
        for(uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], quantities[i]);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function setDefaultURI(string memory defaultURI) external onlyOwner {
        _baseTokenURI = defaultURI;
    }

    function lock(uint256 tokenId) external {
        require(
            lockWhitelists[_msgSender()],
            "AceAnimalNft: must be valid lock whitelist"
        );
        require(_exists(tokenId), "AceAnimalNft: must be valid tokenId");
        require(!lockedTokens[tokenId], "AceAnimalNft: token has already locked");
        lockedTokens[tokenId] = true;
    }

    function isLocked(uint256 tokenId) external view returns (bool) {
        return lockedTokens[tokenId];
    }

    function unlock(uint256 tokenId) external {
        require(
            lockWhitelists[_msgSender()],
            "AceAnimalNft: must be valid lock whitelist"
        );
        require(_exists(tokenId), "AceAnimalNft: must be valid tokenId");
        require(lockedTokens[tokenId], "AceAnimalNft: token has already unlocked");
        lockedTokens[tokenId] = false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
            require(!lockedTokens[startTokenId], "AceAnimalNft: can not transfer locked token");
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "AceAnimalNft: URI query for nonexistent token"
        );
        return string(
            abi.encodePacked(
                _baseTokenURI,
                Strings.toString(tokenId),
                ".json"
            ));
    }
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(withdrawAddress, balance);
  }

  receive() external payable {}

  fallback() external payable {}
}

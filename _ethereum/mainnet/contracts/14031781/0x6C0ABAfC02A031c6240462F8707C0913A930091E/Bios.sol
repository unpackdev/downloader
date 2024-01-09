// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721Enum.sol";
import "./RoyaltyOverrideCore.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @title Biosnft Growing Plants contract
 *
 * @notice Smart Contract provides ERC721 functionality with public and private sales options.
 * @author Chris Phua
 * @dev Credit to Andrey Skurlatov (Project OG Crystal)
 * @dev Credit to Pagzi Tech Inc. 2021 (Project Toy Boogers)
 */
contract Bios is ERC721Enum, EIP2981RoyaltyOverrideCore, Ownable, Pausable {
    // maximum number of tokens that can be purchased per address during public sale
    uint8 public constant MAX_PURCHASE_PER_ADDRESS = 5;

    // maximum number of tokens that can purchase during private sale
    uint8 public constant MAX_PURCHASE_PER_ALLOW_LIST_ADDRESS = 2;

    // maximum number of tokens that can be gift mint per founder address at any time
    uint16 public constant MAX_PURCHASE_PER_FOUNDER_ADDRESS = 512;

    // price in wei per token
    uint256 public constant BIOS_PRICE = 200000000000000000 wei;

    // maximum number of tokens that can be minted on this contract
    uint256 public maxTotalSupply = 1024;

    // founder addresses that can gift mint at any time
    mapping(address => uint16) private _founderAddresses;

    // allowed addresses that can participate in the presale event
    mapping(address => uint8) private _allowList;

    // used minting slots for public sale
    mapping(address => uint8) private _publicSlots;

    // private sale current status
    bool private _privateSale;

    // public sale current status
    bool private _publicSale;

    // base uri for token metadata
    string private _baseTokenURI;

    // address to withdraw funds from contract
    address payable private _withdrawAddress;

    // all token URI's map
    string[] private _tokenURIs;

    // event that emits when private sale changes state
    event privateSaleState(bool active);

    // event that emits when public sale changes state
    event publicSaleState(bool active);

    // event that emits when user bought on private sale
    event addressPrivateSlotsChange(address addr, uint256 slots);

    // event that emits when user bought on public sale
    event addressPublicSlotsChange(address addr, uint256 slots, uint256 totalRemaining);

    /**
     * @param name_ contract name
     * @param symbol_ contract basic symbol
     * @param baseTokenURI base (default) tokenURI with metadata
     * @param withdrawAddress address to withdraw funds from contract
     */
    constructor(string memory name_, string memory symbol_, string memory baseTokenURI, address payable withdrawAddress, address[] memory founderAddresses
    ) ERC721P(name_, symbol_) {
        _baseTokenURI = baseTokenURI;
        _withdrawAddress = withdrawAddress;

        for (uint256 i = 0; i < founderAddresses.length; i++) {
            if (founderAddresses[i] != address(0)) {
                _founderAddresses[founderAddresses[i]] = MAX_PURCHASE_PER_FOUNDER_ADDRESS; // each founder address can only gift mint maximum of 512
            }
        }
    }

    /**
     * @dev check if private sale is active now
     *
     * @return bool if private sale active
     */
    function isPrivateSaleActive() public view virtual returns (bool) {
        return _privateSale;
    }

    /**
     * @dev switch private sale state
     */
    function flipPrivateSaleState() external onlyOwner {
        _privateSale = !_privateSale;
        emit privateSaleState(_privateSale);
    }

    /**
     * @dev check if public sale is active now
     *
     * @return bool if public sale active
     */
    function isPublicSaleActive() public view virtual returns (bool) {
        return _publicSale;
    }

    /**
     * @dev check if public sale is already finished
     *
     * @return bool if public sale active
     */
    function isPublicSaleEnded() public view virtual returns (bool) {
        return maxTotalSupply == totalSupply();
    }

    /**
     * @dev switch public sale state
     */
    function flipPublicSaleState() external onlyOwner {
        _publicSale = !_publicSale;
        emit publicSaleState(_publicSale);
    }

    /**
     * @dev add ETH addresses to allow list
     *
     * Requirements:
     * - private sale must be inactive
     * - numberOfTokens should be less than MAX_PURCHASE value
     *
     * @param addresses address[] array of ETH addresses that need to be allowed
     * @param numberOfTokens uint8 tokens amount for private sale per address
     */
    function addAllowListAddresses(uint8 numberOfTokens, address[] calldata addresses) external onlyOwner 
    {
        require(!_privateSale, "Private sale is now running!");
        require(numberOfTokens > 0, "Number of tokens must be more than 0!");
        require(numberOfTokens <= MAX_PURCHASE_PER_ALLOW_LIST_ADDRESS, "numberOfTokens is higher that MAX_PURCHASE_PER_ALLOW_LIST_ADDRESS limit!");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] != address(0)) {
                _allowList[addresses[i]] = numberOfTokens;
            }
        }
    }

    /**
     * @dev remove ETH addresses from allow list
     *
     * Requirements:
     * - private sale must be inactive
     *
     * @param addresses address[] array of ETH addresses that need to be removed from allow list
     */
    function removeAllowListAddresses(address[] calldata addresses) external onlyOwner
    {
        require(!_privateSale, "Private sale is now running!");

        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 0;
        }
    }

    /**
     * @dev check if address allowed
     *
     * @param _address address ETH address to check
     * @return bool allow list status
     */
    function isAllowed(address _address) public view returns (bool) 
    {
        return (_allowList[_address] > 0 || balanceOf(_address) > 0) ? true : false;
    }

    /**
     * @dev remove ETH addresses from founders
     *
     * @param addresses address[] array of ETH addresses that need to be removed from founders
     */
    function removeFounderAddresses(address[] calldata addresses) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _founderAddresses[addresses[i]] = 0;
        }
    }

    /**
     * @dev check address remaining mint slots for gift mint
     *
     * @param _address address ETH address to check
     * @return uint16 remaining slots
     */
    function addressFounderSaleSlots(address _address) public view returns (uint16)
    {
        return _founderAddresses[_address];
    }

    /**
     * @dev check address remaining mint slots for private sale
     *
     * @param _address address ETH address to check
     * @return uint8 remaining slots
     */
    function addressPrivateSaleSlots(address _address) public view returns (uint8)
    {
        return _allowList[_address];
    }

    /**
     * @dev check address remaining mint slots for public sale
     *
     * @param _address address ETH address to check
     * @return uint8 remaining slots
     */
    function addressPublicSaleSlots(address _address) public view returns (uint8)
    {
        return MAX_PURCHASE_PER_ADDRESS - _publicSlots[_address];
    }

    /**
     * @dev mint new Bios tokens to provided address
     *
     * Requirements:
     * - private sale should be active
     * - sender should have private sale minting slots
     * - sender should pay BIOS price for each token
     *
     * @param numberOfTokens is an amount of tokens to mint
     */
    function mintPrivate(uint8 numberOfTokens) public payable {
      require(_privateSale, "Private sale is not active!");
      require(numberOfTokens > 0, "Number of tokens must be more than 0!");
      require(totalSupply() + numberOfTokens <= maxTotalSupply, "Total supply limit have reached!");
      require(numberOfTokens <= _allowList[msg.sender], "Not enough presale slots to mint tokens!");
      require(BIOS_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct!");

      _allowList[msg.sender] = uint8(_allowList[msg.sender] - numberOfTokens);
      _mintTokens(msg.sender, numberOfTokens);

      payable(_withdrawAddress).transfer(msg.value);

      emit addressPrivateSlotsChange(msg.sender, _allowList[msg.sender]);
    }

    /**
     * @dev mint new Bios tokens to provided address
     *
     * Requirements:
     * - public sale should be active
     * - sender should have public sale minting slots
     * - sender should pay BIOS price for each token
     *
     * @param numberOfTokens is an amount of tokens to mint
     */
    function mintPublic(uint8 numberOfTokens) public payable {
      require(_publicSale, "Public sale is not active!");
      require(numberOfTokens > 0, "Number of tokens must be more than 0!");
      require(numberOfTokens <= MAX_PURCHASE_PER_ADDRESS, "Trying to mint too many tokens!");
      require(totalSupply() + numberOfTokens <= maxTotalSupply, "Total supply limit have reached!");
      require(numberOfTokens + _publicSlots[msg.sender] <= MAX_PURCHASE_PER_ADDRESS, "Address limit have reached!");
      require(BIOS_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct!");

      _publicSlots[msg.sender] = uint8(_publicSlots[msg.sender] + numberOfTokens);
      _mintTokens(msg.sender, numberOfTokens);

      payable(_withdrawAddress).transfer(msg.value);

      emit addressPublicSlotsChange(msg.sender, MAX_PURCHASE_PER_ADDRESS - _publicSlots[msg.sender], maxTotalSupply - totalSupply());
    }

    /**
     * @dev mint gift tokens to provided addresses
     *
     * Requirements:
     * - sender must be founder addresses
     *
     * @param quantity uint8[] is an array of quantity to mint corresponding to the same index in array of recipient address
     * @param recipient address[] is an array of recipient address where new tokens will be minted to
     * 
     */
    function mintGift(uint8[] calldata quantity, address[] calldata recipient) public {
      require(quantity.length == recipient.length, "Provide quantities and recipients");
      
      uint totalQuantity = 0;
      
      for(uint i = 0; i < quantity.length; ++i) {
        require(quantity[i] > 0, "Number of tokens must be more than 0!");

        totalQuantity += quantity[i];
      }

      require(totalSupply() + totalQuantity <= maxTotalSupply, "Total supply limit have reached!");
      require(totalQuantity <= _founderAddresses[msg.sender], "Not enough slots to gift mint tokens!");

       _founderAddresses[msg.sender] = uint16(_founderAddresses[msg.sender] - totalQuantity);

      delete totalQuantity;

      for(uint i = 0; i < recipient.length; ++i) {
        _mintTokens(recipient[i], quantity[i]);
      }
    }

    /**
     * @dev mint new Bios tokens with given
     *
     * @param to is address where to mint new token
     * @param numberOfTokens is an amount of tokens to mint
     */
    function _mintTokens(address to, uint8 numberOfTokens) private {
      for (uint8 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = totalSupply();
        _safeMint(to, tokenId);
        _tokenURIs.push("");
      }
    }

    /**
     * @dev Sets public function that will set
     * `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `sender` must be contract owner
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
      _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = _baseURI();

      return bytes(base).length > 0	? _formatURI(base, _uint2str(tokenId)) : _tokenURI;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
      require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
      super._burn(tokenId);

      if (bytes(_tokenURIs[tokenId]).length != 0) {
        delete _tokenURIs[tokenId];
      }
    }

    /**
     * @dev See {ERC721-baseURI}.
     */
    function _baseURI() internal view virtual returns (string memory) {
      return _baseTokenURI;
    }

    /**
     * @dev Sets new base for tokenURIs
     *
     * @param newBaseURI is the new base URI for tokenURIs
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
      _baseTokenURI = newBaseURI;
    }

    /**
     * @dev check how many tokens is available for mint
     *
     * @return uint256 remaining tokens
     */
    function availableForMint() public view virtual returns (uint256) {
      return (maxTotalSupply - totalSupply());
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    /**
     * @dev format token URI for given token ID
     *
     * @param basePath is tokenURI base path
     * @param tokenId is string representation of SST token ID
     * @return string is formatted tokenURI with metadata
     */
    function _formatURI(string memory basePath, string memory tokenId) internal pure returns (string memory) {
      return string(abi.encodePacked(basePath, tokenId, ".json"));
    }

    /**
     * @dev See {ERC721P-_beforeTokenTransfer}.
     *
     * Useful for scenarios such as preventing trades until the end of an evaluation
     * period, or having an emergency switch for freezing all token transfers in the
     * event of a large bug.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
         super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /**
     * @dev See {Pauseable-_pause}.
     */
    function pause() external onlyOwner {
      _pause();
    }

    /**
     * @dev See {Pauseable-_unpause}.
     */
    function unpause() external onlyOwner {
      _unpause();
    }

    /**
    * https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/token/ERC721.sol
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enum, EIP2981RoyaltyOverrideCore) returns (bool) {
        return ERC721Enum.supportsInterface(interfaceId) || EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setTokenRoyalties}.
     */
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }

    /**
     * @dev format given uint to memory string
     *
     * @param _i uint to convert
     * @return string is uint converted to string
     */
    function _uint2str(uint _i) internal pure returns (string memory) {
      if (_i == 0) {
        return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
        len++;
        j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
      }
      return string(bstr);
    }
}

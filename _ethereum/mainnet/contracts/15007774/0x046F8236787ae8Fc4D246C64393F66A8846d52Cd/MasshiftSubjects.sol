// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MasshiftItems.sol";

//  .___  ___.      ___           _______.     _______. __    __   __   _______ .___________.
//  |   \/   |     /   \         /       |    /       ||  |  |  | |  | |   ____||           |
//  |  \  /  |    /  ^  \       |   (----`   |   (----`|  |__|  | |  | |  |__   `---|  |----`
//  |  |\/|  |   /  /_\  \       \   \        \   \    |   __   | |  | |   __|      |  |     
//  |  |  |  |  /  _____  \  .----)   |   .----)   |   |  |  |  | |  | |  |         |  |     
//  |__|  |__| /__/     \__\ |_______/    |_______/    |__|  |__| |__| |__|         |__|     
//                                                                                         
// dev:\_ Unzyp\ Technology,\ Inc.

contract MasshiftSubjects is ERC721A, IERC721Receiver, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 public immutable amountReserved;
    uint256 public constant MAX_SHIFTLIST_MINT = 2;
    uint256 public constant MAX_MINT = 1;
    uint256 public constant ITEMS_MINT = 4;
    uint256 public reserveMinted;

    uint256 public preSalesStartTime;
    uint256 public publicSalesStartTime;

    bool public stakingPaused;
    bool public mintingPaused;
    bool public isPausable;

    string private _currentBaseURI;

    address public itemContract;
    address public vaultAddress;
    address public cSigner;

    mapping(uint256 => uint256[]) private items;
    mapping(uint256 => string) public customNames;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxBatchMintSize,
        uint256 _collectionSize,
        uint256 _amountReserved,
        bool _stakingPaused,
        bool _mintingPaused,
        uint256 _presaleStartTime,
        uint256 _publicStartTime,
        address _cSigner
    ) ERC721A(_name, _symbol, _maxBatchMintSize, _collectionSize) {
        amountReserved = _amountReserved;
        stakingPaused = _stakingPaused;
        mintingPaused = _mintingPaused;
        preSalesStartTime = _presaleStartTime;
        publicSalesStartTime = _publicStartTime;
        cSigner = _cSigner;
    }

    modifier mintable() {
        require(mintingPaused == false, "Mint is disabled");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isPreSaleActive() {
        require(preSalesStartTime > 0 && block.timestamp >= preSalesStartTime, "Presale is not active");
        _;
    }

    modifier isPublicSaleActive() {
        require(publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime, "Public sale is not active");
        _;
    }

    /**
     * ======================================================================================
     *
     *  Token Minting
     *
     * ======================================================================================
     */

    function presaleClaimSubject(bytes memory _signature) external mintable callerIsUser isPreSaleActive {
        require(numberMinted(msg.sender) < MAX_SHIFTLIST_MINT, "You've already claimed, fren.");
        require((totalSupply() + MAX_SHIFTLIST_MINT) < collectionSize, "Subjects are all minted");
        require(isMsgValid(_signature) == true, "Invalid Signature"); // Signed Whitelist Minting Only

        // Claim subject
        _safeMint(msg.sender, MAX_SHIFTLIST_MINT);

        // Claim items
        (bool success,) = payable(address(itemContract)).call(abi.encodeWithSignature("claimItem(uint256)", MAX_SHIFTLIST_MINT * ITEMS_MINT));
        require(success);
    }

    function publicClaimSubject(bytes memory _signature) external mintable callerIsUser isPublicSaleActive {
        require(numberMinted(msg.sender) < MAX_MINT, "You've already claimed, fren.");
        require((totalSupply() + MAX_MINT) < collectionSize, "Subjects are all minted");
        require(isMsgValid(_signature) == true, "Invalid Signature"); // Signed Whitelist Minting Only

        // Claim subject
        _safeMint(msg.sender, MAX_MINT);
        
        // Claim items with random numbers 2 ~ 4
        (bool success, ) = payable(address(itemContract)).call(abi.encodeWithSignature("claimItem(uint256)", MAX_MINT * random()));
        require(success);
    }

    /**
        @dev Reserved Token Minting
    */
    function mintReserved(address _receiver, uint256 _amount)
        external
        mintable
        onlyOwner
    {
        require(totalSupply() < collectionSize, "All Subjects are minted");
        require(
            reserveMinted + _amount < amountReserved + 1,
            "Reserved are all minted"
        );
        reserveMinted += _amount;

        // Claim subject
        _safeMint(_receiver, _amount);

        // Claim items
        (bool success, ) = payable(address(itemContract)).call(abi.encodeWithSignature("devMint(address,uint256)", _receiver, _amount * ITEMS_MINT));
        require(success);
    }

    function random() private view returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 2;
        randomnumber = randomnumber + 2;
        return randomnumber;
    }

    /**
     * ======================================================================================
     *
     *  Item Equipment and Staking
     *
     * ======================================================================================
     */

    function getOwnedTokens(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_address);
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = tokenOfOwnerByIndex(_address, i);
        }
        return result;
    }

    /**
     * @dev Receiver function to receive the NFT Tokens, and then added to item collection associated with Subject Token Id
     * @param _from address of the stakeholder
     * @param _tokenId the token id
     * @return selector
     */
    function onERC721Received(
        address _from,
        address,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        // locate the subject which the item should be put
        uint256 subjectId = toUint256(data);
        require(msg.sender == itemContract, "Invalid ERC721 Transferred");
        require(
            ownerOf(subjectId) == _from,
            "Invalid Staking. Subject does not belongs to the staker."
        );
        items[subjectId].push(_tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @dev Get staked items
     * @param _tokenId  The Subject Token Id
     * @return array of staked token id
     */
    function stakedItems(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return items[_tokenId];
    }

    /**
     * @dev Check if current user staked the item, and return the index of staked item
     * @notice if it returns an invalid index(eg. index > arr.length), then the item is absense in this array.
     * @notice we use this method because it can perform find and return the index within one operation.
     * @param _itemTokenId Mypunks Item Token Id
     * @param _subjectTokenId Subject Token Id
     * @return index of the token id, if no item present, return a invalid number
     */
    function isItemStaked(uint256 _itemTokenId, uint256 _subjectTokenId)
        public
        view
        returns (uint256)
    {
        // Default value is invalid
        uint256 index = items[_subjectTokenId].length + 1;

        for (uint256 i = 0; i < items[_subjectTokenId].length; i++) {
            if (items[_subjectTokenId][i] == _itemTokenId) {
                index = i;
            }
        }

        return index;
    }

    /**
     * @dev Remove an index from an array
     * @param _index item index
     * @param _subjectTokenId the subject token id
     */
    function remove(uint256 _index, uint256 _subjectTokenId) private {
        // move array elements
        for (uint256 i = _index; i < items[_subjectTokenId].length - 1; i++) {
            items[_subjectTokenId][i] = items[_subjectTokenId][i + 1];
        }
        // pop the last element
        items[_subjectTokenId].pop();
    }

    /**
     * @dev Remove an index from an array
     * @param _itemTokenIds ids of item to withdraw
     * @param _subjectTokenId id of subject to withdraw from
     */
    function withdrawSubject(uint256[] memory _itemTokenIds, uint256 _subjectTokenId)
        public
    {
        require(stakingPaused == false, "Staking Paused");
        require(
            ownerOf(_subjectTokenId) == msg.sender,
            "Unauthorized withdrawal. You must be the owner."
        );

        for (uint256 i = 0; i < _itemTokenIds.length; i++) {
            uint256 itemIndex = isItemStaked(_itemTokenIds[i], _subjectTokenId);
            // Check if the item has staked by user
            require(
                itemIndex < items[_subjectTokenId].length,
                "Invalid withdrawal. This subject does not have the item."
            );
            // Remove the item from staking
            remove(itemIndex, _subjectTokenId);
            MasshiftItems Item = MasshiftItems(itemContract);
            Item.unstakeItem(msg.sender, _itemTokenIds[i]);
        }
    }

    /**
     * ======================================================================================
     *
     *  Naming
     *
     * ======================================================================================
     */

    /**
        @dev Set a customized name of token. Caller must be the token owner.
    */
    function setName(uint256 _tokenId, string memory _customName) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You're not authorized to set the name"
        );
        require(bytes(_customName).length <= 20, "Exceed Maximum Name Length");
        customNames[_tokenId] = _customName;
    }

    /**
     * ======================================================================================
     *
     *  Contract Configurations
     *
     * ======================================================================================
     */

    function pauseMint(bool _paused) external onlyOwner {
        mintingPaused = _paused;
    }

    function pauseStaking(bool _paused) external onlyOwner {
        stakingPaused = _paused;
    }

    function withdraw() external onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory _URI)
        public
        onlyOwner
    {
        _currentBaseURI = _URI;
    }

    function setItemContract(address _address)
        external
        onlyOwner
    {
        itemContract = _address;
    }

    // 1655906400: start time at 22 Jun 2022 (9 PM GMT+7) in seconds
    function setPresaleStartTime(uint256 startTime) 
        external 
        onlyOwner 
    {
        preSalesStartTime = startTime;
    }

    // 1655992800: end time at 23 Jun 2022 (9 PM GMT+7) in seconds
    function setPublicStartTime(uint256 startTime) 
        external 
        onlyOwner 
    {
        publicSalesStartTime = startTime;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function isMsgValid(bytes memory _signature) private view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(address(this), msg.sender)
        );
        address signer = messageHash.toEthSignedMessageHash().recover(
            _signature
        );
        return cSigner == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        cSigner = _signer;
    }

    function isFullyMinted() public view returns (bool) {
        return totalSupply() >= (collectionSize - amountReserved);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
    ) internal virtual override {
      super._beforeTokenTransfers(from, to, startTokenId, quantity);

      require(!isPausable, "ERC721A: token transfer while paused");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public override {
      super.setApprovalForAll(operator, approved);

      if(!isFullyMinted()){
        revert("ERC721A: Subjects must be fully minted to be tradable");
      }
    }
}
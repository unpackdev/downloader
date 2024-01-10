// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./Math.sol";

contract CyberCosmosWorld is ERC721A, Ownable, ReentrancyGuard, Pausable {

    using Math for uint256;

    mapping(address => uint8) public preSaleMintedVipPl; // Amounts of minted tokens by users on the presale for VIP Pink List
    mapping(address => uint8) public preSaleMintedPl; // Amounts of minted tokens by users on the presale for Pink List
    mapping(address => uint8) public freeMintAddresses; // Amounts of minted tokens by users on the presale for Pink List

    uint8 constant public preSaleLimitPerUserVipPl = 5;  // Max amount of tokens available for mint at the pre sale per address
    uint8 constant public preSaleLimitPerUserPl = 50;  // Max amount of tokens available for mint at the pre sale per address
    uint8 public amountForGiveAway = 200;  // Amount of tokens reserved for give away
    uint8 public publicSaleLimitPerTx = 10;    // Max amount of tokens available for mint at the public sale per transaction
    uint8 public saleState = 1; // 0 - No sale, 1 - VIP PL, 2 - PL , 3 - Public Sale

    uint16 public mintCounter;  // The next token ID to be minted (not equal to totalSupply because of the give away)
    uint16 public airdropCounter; // Current amount of airdropped tokens
    uint16 public maxTotalSupply = 10000;   // Max amount of tokens available for mint in total
    uint16 public preSaleTokenLimit = 8000;    // Max amount of tokens available for mint at the pre sale
    
    address public communityFundAddress = 0x86eA9D9ff386BCaD2D18b42192b40F264a77a679;    // The Community Fund address
    address public withdrawAddress = 0x27BedE3c03096A5D7cd764874D35A525EF45689b;    // The Withdraw Fund address
    
    string public baseURI;  // Base URI for tokens
    string _prerevealUri = "ipfs://QmSLBj2jM8Dt2sYiDyHQnWAB9nN5jrsA1BVah17ohKjjig/";

    bool public uriSet; // If base URI set or not
    bool public freeMintActive;

    uint256 public publicSalePrice = 0.1 ether;   // Token price at the public sale stage
    uint256 constant public preSaleVipPlPrice = 0.02 ether;  // Token price at the pre sale stage for VIP Pink List
    uint256 constant public preSalePlPrice = 0.08 ether;  // Token price at the pre sale stage for Pink List
    
    bytes32 public merkleRootVipPl;    // Merkle root for the whitelist
    bytes32 public merkleRootPl;    // Merkle root for the whitelist

    event PreSaleMintVipPl(address user, uint256 amount);
    event PreSaleMintPl(address user, uint256 amount);
    event PublicSaleMint(address user, uint256 amount);
    event FreeMint(address user, uint256 amount);
    event SoldOut();
    event GiveAway(address[] addresses);

    // Merkle Roots
    bytes32 _merkleRootVipPl = 0xdd055a3edf8accecd0b84325fc98a421bbeddd560e03274a314ccca6f23f3519;
    bytes32 _merkleRootPl = 0xdd055a3edf8accecd0b84325fc98a421bbeddd560e03274a314ccca6f23f3519;

    /*
    * @param _name The name of the NFT
    * @param _symbol The symbol of the NFT
    */
    constructor (
        string memory _name, 
        string memory _symbol
    ) 
        ERC721A(_name, _symbol) 
    {
        require(uint256(_merkleRootVipPl) > 0, "invalid MerkleRoot for VIP PL");
        require(uint256(_merkleRootPl) > 0, "invalid MerkleRoot for PL");
        merkleRootVipPl = _merkleRootVipPl;
        merkleRootPl = _merkleRootPl;
        baseURI = _prerevealUri;
    }

    /*
    * @notice Distrubites specified amounts of ETH to the Community Fund
    * @dev Only owner can call it
    * @param _amountToCommunityFund Amount of ETH for the Community Fund
    */
    function distributeFunds(uint256 _amountToCommunityFund) internal onlyOwner {
        uint256 balance = address(this).balance;
        require(_amountToCommunityFund <= balance, "not enough balance");
        _sendETH(payable(communityFundAddress), _amountToCommunityFund);
    }

    /*
    * @notice returns Balance of the contract
    * @dev Only owner can call it
    */
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    /*
    * @notice Sets Merkle root for VIP PL
    * @dev Only owner can call it
    * @param _newVipPlRoot New Merkle root
    */
    function setMerkleRootVipPl(bytes32 _newVipPlRoot) external onlyOwner {
        merkleRootVipPl = _newVipPlRoot;
    }

    /*
    * @notice Sets Free Mint Active
    * @dev Only owner can call it
    * @param _newFreeMintActive New Merkle root
    */
    function setFreeMintActive(bool _newFreeMintActive) external onlyOwner {
        freeMintActive = _newFreeMintActive;
    }

    /*
    * @notice Sets Sale State
    * @dev Only owner can call it
    * @param _newSaleState New Merkle root
    */
    function setSaleState(uint8 _newSaleState) external onlyOwner {
        saleState = _newSaleState;
    }

    /*
    * @notice Sets Merkle root for PL
    * @dev Only owner can call it
    * @param _newPlRoot New Merkle root
    */
    function setMerkleRootPl(bytes32 _newPlRoot) external onlyOwner {
        merkleRootPl = _newPlRoot;
    }

    /*
    * @notice Sets the Community Fund Address
    * @dev Only owner can call it
    * @param _communityFundAddress The new address of the Commmunity Fund
    */
    function setCommunityFundAddress(address _communityFundAddress) external onlyOwner {
        require(_communityFundAddress != address(0), "communityFundAddress is 0");
        communityFundAddress = _communityFundAddress;
    }

    /*
    * @notice Pauses contract
    * @dev Only owner can call it
    */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /*
    * @notice Unpauses contract
    * @dev Only owner can call it
    */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /*
    * @notice Mints specified amount of tokens on the VIP Pink List and registers 
    * the user if correct MerkleProof was submitted. Must be called if the 
    * user isn't registered yet (didn't mint tokens)
    * @dev Non reentrant
    * @param _amount Amount of tokens to mint
    * @param _proof Merkle proof for the user
    */
    function preSaleMintVipPl(
        uint256 _amount, 
        bytes32[] memory _proof
    ) 
        external 
        payable 
        nonReentrant
        whenNotPaused
    {
        require(preSaleMintedVipPl[_msgSender()] == 0, "already registered");
        require(_verifyVipPL(_leaf(_msgSender()), _proof), "incorrect proof");
        _preSaleMintVipPl(_amount);
    }

    /*
    * @notice Mints specified amount of tokens on the VIP Pink List. Must be called 
    * if the user already registered (already did mint tokens)
    * @dev Non reentrant
    * @param _amount Amount of tokens to mint
    */
    function preSaleMintVipPl(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(preSaleMintedVipPl[_msgSender()] > 0, "not registered");
        _preSaleMintVipPl(_amount);
    }

    /*
    * @notice Mints specified amount of tokens on the Pink List and registers 
    * the user if correct MerkleProof was submitted. Must be called if the 
    * user isn't registered yet (didn't mint tokens)
    * @dev Non reentrant
    * @param _amount Amount of tokens to mint
    * @param _proof Merkle proof for the user
    */
    function preSaleMintPl(
        uint256 _amount, 
        bytes32[] memory _proof
    ) 
        external 
        payable 
        nonReentrant
        whenNotPaused
    {
        require(preSaleMintedPl[_msgSender()] == 0, "already registered");
        require(_verifyPL(_leaf(_msgSender()), _proof), "incorrect proof");
        _preSaleMintPl(_amount);
    }

    /*
    * @notice Mints specified amount of tokens on the Pink List. Must be called 
    * if the user already registered (already did mint tokens)
    * @dev Non reentrant
    * @param _amount Amount of tokens to mint
    */
    function preSaleMintPl(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(preSaleMintedPl[_msgSender()] > 0, "not registered");
        _preSaleMintPl(_amount);
    }

    /*
    * @notice Mints specified amount of tokens on the public sale
    * @dev Non reentrant. Emits PublicSaleMint event
    * @param _amount Amount of tokens to mint
    */
    function publicSaleMint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(saleState == 3, "public sale isn't active");
        require(_amount > 0 && _amount <= publicSaleLimitPerTx, "invalid amount");
        uint256 maxTotalSupply_ = maxTotalSupply;
        uint256 totalSupply_ = totalSupply();
        require(totalSupply_ + _amount <= maxTotalSupply_, "already sold out");
        require(mintCounter + _amount <= maxTotalSupply_ - amountForGiveAway, "the rest is reserved");
        _buyAndRefund(_amount, publicSalePrice);
        if (totalSupply_ + _amount == maxTotalSupply_) emit SoldOut();
        emit PublicSaleMint(_msgSender(), _amount);
    }

    /*
    * @notice Mints specified amount of tokens on the public sale
    * @dev Non reentrant. Emits PublicSaleMint event
    * @param _amount Amount of tokens to mint
    */
    function freeMint(uint8 _amount) external payable nonReentrant whenNotPaused {
        require(saleState != 0, "sale isn't active");
        require(_amount == 1, "invalid amount");
        require(freeMintActive, "Free Mint is not active");
        require(freeMintAddresses[_msgSender()] == 0, "already minted");
        require(balanceOf(_msgSender()) >= 5, "doesn't own 5 or more nfts");
        uint256 maxTotalSupply_ = maxTotalSupply;
        uint256 totalSupply_ = totalSupply();
        require(totalSupply_ + _amount <= maxTotalSupply_, "already sold out");
        require(mintCounter + _amount <= maxTotalSupply_ - amountForGiveAway, "the rest is reserved");
        _buyAndRefund(_amount, 0);
        freeMintAddresses[_msgSender()] += uint8(_amount);
        if (totalSupply_ + _amount == maxTotalSupply_) emit SoldOut();
        emit FreeMint(_msgSender(), _amount);
    }

    /*
    * @notice Mints specified IDs to specified addresses
    * @dev Only owner can call it. Lengths of arrays must be equal. 
    * @param _accounts The list of addresses to mint tokens to
    */
    function giveaway(address[] memory _accounts) external onlyOwner {
        uint256 maxTotSup = maxTotalSupply;
        uint256 currentTotalSupply = totalSupply();
        require(_accounts.length <= publicSaleLimitPerTx, "Limit per transaction exceeded");
        require(airdropCounter + _accounts.length <= amountForGiveAway, "limit for airdrop exceeded");
        require(currentTotalSupply + _accounts.length <= maxTotSup, "maxTotalSupply exceeded");
        uint256 counter = currentTotalSupply;
        for (uint256 i; i < _accounts.length; i++) {
            _safeMint(_accounts[i], uint8(1));
            counter++;
        }
        airdropCounter += uint16(_accounts.length);
        if (currentTotalSupply + _accounts.length == maxTotSup) emit SoldOut();  // emit SoldOut in case some tokens were airdropped after the sale
        emit GiveAway(_accounts);
    }

    /*
    * @notice Sets base URI for tokens
    * @dev Only owner can call it
    * @param _newBaseURI The new base URI
    */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        uriSet = true;
    }


    /*
    * @notice Sets Public Sale Price
    * @dev Only owner can call it
    * @param _newBaseURI The new base URI
    */
    function setPublicSalePrice(uint256 _newPublicSalePrice) external onlyOwner {
        publicSalePrice = _newPublicSalePrice;
    }

    /*
    * @notice Withdraws specified amount of ETH to specified address
    * @dev Only owner can call it
    * @param _to The address of ETH receiver
    * @param _amount The amount of ETH to withdraw
    */
    function withdrawTo(uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= _amount, "unsufficient balance");
        uint256 three_percent = (_amount / 100) * 3;
        distributeFunds(three_percent);
        _sendETH(payable(withdrawAddress), _amount - three_percent);
    }

    /*
    * @notice Sets Amount Reserved For Giveaway
    * @dev Only owner can call it
    * @param _newAmountForGiveAway The new amount for give away
    */
    function setAmountForGiveAway(uint8 _newAmountForGiveAway) external onlyOwner {
        amountForGiveAway = _newAmountForGiveAway;
    }

    /*
    * @notice Sets Pre Sale Token Limit
    * @dev Only owner can call it
    * @param _newPreSaleTokenLimit The new Pre Sale Token Limit
    */
    function setPreSaleTokenLimit(uint8 _newPreSaleTokenLimit) external onlyOwner {
        preSaleTokenLimit = _newPreSaleTokenLimit;
    }

    /*
    * @notice Sets Public Sale Limit Per Transaction
    * @dev Only owner can call it
    * @param _newPublicSaleLimitPerTxn The new Public Sale Limit Per Transaction
    */
    function setPublicSaleLimitPerTxn(uint8 _newPublicSaleLimitPerTxn) external onlyOwner {
        publicSaleLimitPerTx = _newPublicSaleLimitPerTxn;
    }

    /*
    * @dev The main logic for the pre sale mint. Emits PreSaleMint event
    * @param _amount The amount of tokens 
    */
    function _preSaleMintVipPl(uint256 _amount) private {
        require(saleState == 1, "VIP Presale isn't active");
        require(_amount > 0, "invalid amount");
        require(preSaleMintedVipPl[_msgSender()] + _amount <= preSaleLimitPerUserVipPl, "limit per user exceeded");
        uint256 totalSupply_ = totalSupply();
        require(totalSupply_ + _amount <= preSaleTokenLimit, "presale token limit exceeded");
        _buyAndRefund(_amount, preSaleVipPlPrice);
        preSaleMintedVipPl[_msgSender()] += uint8(_amount);
        emit PreSaleMintVipPl(_msgSender(), _amount);
    }

    /*
    * @dev The main logic for the pre sale mint. Emits PreSaleMint event
    * @param _amount The amount of tokens 
    */
    function _preSaleMintPl(uint256 _amount) private {
        require(saleState == 2, "Presale isn't active");
        require(_amount > 0, "invalid amount");
        require(preSaleMintedPl[_msgSender()] + _amount <= preSaleLimitPerUserPl, "limit per user exceeded");
        uint256 totalSupply_ = totalSupply();
        require(totalSupply_ + _amount <= preSaleTokenLimit, "presale token limit exceeded");
        _buyAndRefund(_amount, preSalePlPrice);
        preSaleMintedPl[_msgSender()] += uint8(_amount);
        emit PreSaleMintPl(_msgSender(), _amount);
    }

    /*
    * @dev Mints tokens for the user and refunds ETH if too much was passed
    * @param _amount The amount of tokens 
    * @param _price The price for each token 
    */
    function _buyAndRefund(uint256 _amount, uint256 _price) internal {
        uint256 totalCost = _amount * _price;
        require(msg.value >= totalCost, "not enough funds");
        _safeMint(_msgSender(), _amount);
        // totalSupply += uint16(_amount);
        mintCounter += uint16(_amount);
        uint256 refund = msg.value - totalCost;
        if (refund > 0) {
            _sendETH(payable(_msgSender()), refund);
        }
    }

    /*
    * @dev sends ETH to the specified address
    * @param _to The receiver
    * @param _amount The amount of ETH to send 
    */
    function _sendETH(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "send ETH failed");
    }

    /*
    * @dev Returns the base URI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!uriSet) return _baseURI();
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), ".json"));
    }

    function setUriSet(bool status) external {
        uriSet = status;
    }

    /*
    * @dev Returns the leaf for Merkle tree
    * @param _account Address of the user
    * @param _userId ID of the user
    */
    function _leaf(address _account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account));
    }

    /*
    * @dev Verifies if the proof is valid or not for VIP PL
    * @param _leaf The leaf for the user
    * @param _proof Proof for the user
    */
    function _verifyVipPL(bytes32 leaf, bytes32[] memory _proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRootVipPl, leaf);
    }

    /*
    * @dev Verifies if the proof is valid or not for PL
    * @param _leaf The leaf for the user
    * @param _proof Proof for the user
    */
    function _verifyPL(bytes32 leaf, bytes32[] memory _proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRootPl, leaf);
    }

    /*
    * @dev receive() function to let the contract accept ETH
    */
    receive() external payable{}

}

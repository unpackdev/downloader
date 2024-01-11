// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/**
  __  __      _        __  __                  _     _          
 |  \/  |    | |      |  \/  |                | |   (_)         
 | \  / | ___| |_ __ _| \  / | ___  _ __ _ __ | |__  _  ___ ___ 
 | |\/| |/ _ | __/ _` | |\/| |/ _ \| '__| '_ \| '_ \| |/ _ / __|
 | |  | |  __| || (_| | |  | | (_) | |  | |_) | | | | |  __\__ \
 |_|  |_|\___|\__\__,_|_|  |_|\___/|_|  | .__/|_| |_|_|\___|___/
                                        | |                     
                                        |_|                     
 */
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";


contract MetaMorphies is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string _baseTokenURI;
    bool internal _isWhitelistMintActive = false;
    bool internal _isPublicMintActive = false;

    /* Withdraw adddresses */
    address t1 = 0x7E9b094cE2BB9d9fe8761BDa3A53B6de02a35Bd6;
    address t2 = 0x180b7621b0B957e5CD68dC0C0a469adC996F314E;
    address t3 = 0x5d860c2E6Dd51BEB36F63f410fA00332e7B8e813;

    address t4 = 0x3c238729d5076f9C5d7eD4DBa88C8c209BF508F5;
    address t5 = 0xfb94D6cC53Ca85E77Dfd494988E40F38DA9B3278;
    address t6 = 0x1632e583835246Cb485BCbc39d84160a1A9324dD;

    /* emergency address */
    address public emergencyAddress = 0x7E9b094cE2BB9d9fe8761BDa3A53B6de02a35Bd6;

    /* Whitelist mint price */
    uint256 public whitelistMintPrice;

    /* Public mint price */
    uint256 public publicMintPrice;

    /* Max token supply */
    uint256 public MAX_SUPPLY = 5000;

    uint256 public maxWhitelistMintable = 2001;

    /* Number of tokens minted from whitelist mint */
    uint256 public numberOfWhitelistMints;

    /* Merkle root for verifying the whitelist */
    bytes32 public whitelistMerkleRoot;

    /* Event for new morphie mint */
    event MorphieAdopted(
        address indexed owner,
        uint256 amountOfTokens,
        uint256 totalPrice
    );

    constructor() ERC721A("MetaMorphies", "MORPHIES") {
        whitelistMintPrice = 0.01 ether;
        publicMintPrice = 0.02 ether;
    }

    /**
     * @dev Mints 'num' number of morphies to msg.sender.
     * @param num the number of tokens to be minted.
     * Only 10 tokens can be minted per wallet, including the whitelist mints.
     */
    function adoptMorphies(uint256 num) external payable nonReentrant {
        require(_isPublicMintActive, "MetaMorphies: Public mint is not active");

        require(_numberMinted(msg.sender) + num < 11, "MetaMorphies: Per wallet mint limit reached");

        uint256 totalPrice = publicMintPrice.mul(num);
        require(
            totalPrice == msg.value,
            "MetaMorphies: Incorrect amount of eth sent"
        );

        require(
            totalSupply() + num <= MAX_SUPPLY,
            "MetaMorphies: Exceeds maximum Morphies supply"
        );

        _safeMint(msg.sender, num);

        emit MorphieAdopted(msg.sender, num, totalPrice);
    }

    /**
     * @dev Gives away reserved morphies.
     * @param _to the address to which the tokens will be minted.
     * @param _amount the amount of tokens to give away.
     */
    function giveAway(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    /**
     * @dev Whitelist mints a morphie.
     * @param count the amount of tokens to be whitelist minted.
     * @param allowance the amount of tokens the address is allowed to whitelist mint.
     * @param proof the merkle proof for the address.
     */
    function whitelistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _isWhitelistMintActive,
            "MetaMorphies: Whitelist minting is not active"
        );

        require(numberOfWhitelistMints + count < maxWhitelistMintable, "MetaMorphies: Whitelist limit maxxed out.");

        require(
            _verify(
                _leaf(Strings.toString(allowance), payload),
                proof,
                whitelistMerkleRoot
            ),
            "Invalid Merkle Tree proof supplied."
        );

        uint64 wlMinted = _getWlMinted(msg.sender);
        require(
            wlMinted + count <= allowance,
            "Exceeds whitelist mint limit."
        );

        uint256 totalPrice = whitelistMintPrice.mul(count);
        require(totalPrice == msg.value, "Insufficient ETH sent.");

        numberOfWhitelistMints = numberOfWhitelistMints + count;

        _setWlMinted(msg.sender, wlMinted + uint64(count));

        _safeMint(msg.sender, count);

        emit MorphieAdopted(msg.sender, count, totalPrice);
    }

    /** 
    * @dev Changes the public mint active state.
    @param isActive the new value for _isPublicMintActive
    */
    function setPublicMintActive(bool isActive) external onlyOwner {
        _isPublicMintActive = isActive;
    }

    /**
     * @dev Changes the whitelist mint active state.
     * @param isActive The new value for _isWhitelistMintActive
     */
    function setWhitelistMintActive(bool isActive) external onlyOwner {
        _isWhitelistMintActive = isActive;
    }

    /**
     * @dev Verify merkle proof.
     * @param leaf the leaf of the tree to verify.
     * @param proof the merkle proof.
     */
    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev Get a leaf of the merkle tree.
     * @param allowance The whitelist mint allownace for msg.sender.
     * @param payload string encoded address of msg.sender.
     */
    function _leaf(string memory allowance, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    /**
     * @dev Get whitelist allowance for msg.sender.
     * @param allowance The whitelist mint allowance for msg.sender.
     * @param proof The merkle proof.
     */
    function getAllowance(string memory allowance, bytes32[] calldata proof)
        external
        view
        returns (string memory)
    {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(_leaf(allowance, payload), proof, whitelistMerkleRoot),
            "Invalid Merkle Tree proof supplied."
        );
        return allowance;
    }

    /**
     * @dev Returns the number of tokens minted via whitelistMint
     * @param user The address of the user.
    */
    function _getWlMinted(address user) private view returns (uint64) {
        return _getAux(user);
    }

    /**
     * @dev Sets the number of tokens minted per user via whitelistMint
     * @param user The user who mints the tokens.
     * @param wlMinted The amount of tokens.
    */
    function _setWlMinted(address user, uint64 wlMinted) private {
        _setAux(user, wlMinted);
    }

    /**
     * @dev Update the root of the whitelist merkle tree.
     * @param _whitelistMerkleRoot The new root of the tree.
     */
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /**
     * @dev Set base URI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Returns the token URI for a token.
     * @param _tokenId The id of the token.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "MetaMorphies: Token does not exist");
        return
            string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    /** 
    @dev Sets the public mint price
    @param _publicMintPrice The new public mint price
    */
    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        require(!_isPublicMintActive, "MetaMorphies: Public mint is active");
        publicMintPrice = _publicMintPrice;
    }

    /**
     * @dev Sets the whitelist mint price.
     * @param _whitelistMintPrice the new whitelist mint price.
     */
    function setWhitelistMintPrice(uint256 _whitelistMintPrice)
        external
        onlyOwner
    {
        require(
            !_isWhitelistMintActive,
            "MetaMorphies: Whitelist mint is active"
        );
        whitelistMintPrice = _whitelistMintPrice;
    }

    /**
     * @dev Sets the emergency safe address.
     * @param _emergencyAddress The new emergency address.
     */
    function setEmergencyAddress(address _emergencyAddress) external onlyOwner {
        require(
            _emergencyAddress != address(0),
            "MetaMorphies: Emergency address can't be set to zero address"
        );
        emergencyAddress = _emergencyAddress;
    }

    /** 
     * @dev Sets the max whitelist mintable amount.
     * @param maxMintable The new max whitelist mintable amount. 
     */
    function setMaxWhitelistMintable(uint256 maxMintable) external onlyOwner {
        maxWhitelistMintable = maxMintable;
    }

    /**
     * @dev Check if whitelist mint is currently active.
     */
    function isWhitelistMintActive() external view returns (bool) {
        return _isWhitelistMintActive;
    }

    /**
     * @dev Check if public mint is currently active.
     */
    function isPublicMintActive() external view returns (bool) {
        return _isPublicMintActive;
    }

    /**
     * @dev Pays out revenue from the contract.
     */
    function withdrawAll() external payable onlyOwner nonReentrant {
        uint256 _balance = address(this).balance;

        uint256 amountOne = _balance.mul(3200).div(10000);

        uint256 amountTwo = _balance.mul(3100).div(10000);

        uint256 amountThree = _balance.mul(2600).div(10000);

        uint256 amountFour = _balance.mul(500).div(10000);

        uint256 amountFive = _balance.mul(400).div(10000);

        uint256 amountSix = _balance.mul(200).div(10000);

        (bool t1Success, ) = t1.call{value: amountOne}("");
        require(t1Success, "Failed t1 payout.");

        (bool t2Success, ) = t2.call{value: amountTwo}("");
        require(t2Success, "Failed t2 payout.");

        (bool t3Success, ) = t3.call{value: amountThree}("");
        require(t3Success, "Failed t3 payout.");

        (bool t4Success, ) = t4.call{value: amountFour}("");
        require(t4Success, "Failed t4 payout.");

        (bool t5Success, ) = t5.call{value: amountFive}("");
        require(t5Success, "Failed t5 payout.");

        (bool t6Success, ) = t6.call{value: amountSix}("");
        require(t6Success, "Failed t6 payout.");
    }

    /** 
    @dev Emergency withdraws everything.
    */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = emergencyAddress.call{value: address(this).balance}("");
        require(success, "MetaMorphies: Withdraw failed.");
    }
}

/*
                              *(%&@@@&%/,                             
                  ,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#                  
             /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.            
          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/         
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#       
      (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.     
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*    
    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.   
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(  
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
  %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@& 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@& 
 #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
   @@@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.@@@@@@@&  
      ..     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&     ..     
              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%             
               %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,              
                 &@@@@@@@@@@@,           @@@@@@@@@@@@/                
                    #@@@@@@&               @@@@@@@,                   
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./MaximPresale.sol";
import "./TheMaximals.sol";

/**
* Maxim Coin Claim contract
* 50% - Presale Claim
* 20% - NFT Claim
* 30% - goes to LP
* 
* NFT Holders claim
* Computation is based on the number of NFTs
* 1 NFT = ( MaxSupply * 0.25 ) / 10000
* NFT used to claim an NFT will be marked as claimed and cannot be used again
* 
* Presale Claim
* Computation of claim is based on the amount purchased
* tokenUnitPrice = (MaxSupply * 0.25) / totalFundsRaised
* participantAllocation = purhaseCost * tokenUnitPrice
* 
* All unclaimed tokens by the end of claim period shall be burned
**/

contract MaximClaim is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    IERC20 public maximToken; // Reference to your $MAXIM token contract
    Maximals public maximalsNftContract; // Reference to NFT contract
    MaximPresaleContract maximPresaleContract; //Reference to Presale Contract
    
    uint256 public presaleAllocation;
    uint256 public nftHoldersAllocation;
    uint256 public totalTokenSupply = 1e12 * 1e18;

    bytes32 private nftHoldingsMerkleRoot;

    // Mapping to track claimed NFTs by address and token ID
    mapping(address => uint256) public claimed;

    event Claim(address indexed recipient, uint256 amount);
    event TokensDeposited(address indexed user, uint256 amount);
    event TokensBuned(address indexed user, uint256 amount);

    constructor() {
        maximToken = IERC20(0x64a7F7Ce1719fb64D8b885eDe9D24779e7456d3a);
        maximalsNftContract = Maximals(0xB8a52CBF0a322b5162173984b58510E5BF264D81);
        maximPresaleContract = MaximPresaleContract(0x6d563837e762e79eD786058c7DD21D957099a8aB);

        presaleAllocation = 500000000000000000000000000000; //50% allocated to presale
        nftHoldersAllocation = 200000000000000000000000000000; 

        _pause();
    }

    //setters
    function setPresaleAllocation(uint256 _amount) public onlyOwner {
        presaleAllocation = _amount;
    }
    function setNftHoldersAllocation(uint256 _amount) public onlyOwner {
        nftHoldersAllocation = _amount;
    }
    function setHoldingsMerkleRoot(bytes32 _nftHoldingsMerkleRoot) public onlyOwner {
        nftHoldingsMerkleRoot = _nftHoldingsMerkleRoot;
    }
    function setMaximToken(address _maximToken) public onlyOwner {
        maximToken = IERC20(_maximToken);
    }
    function setMaximalsNFTToken(address _maximalsNFTToken) public onlyOwner {
       maximalsNftContract = Maximals(_maximalsNFTToken);
    }
    function setMaximPresaleContract(address _maximPresaleContract) public onlyOwner {
        maximPresaleContract = MaximPresaleContract(_maximPresaleContract);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    /**
    * 
    * Token Claim
    * checks account elegibility
    * -presale participation - calls presale function to get participation amount
    * -holders snapshot - checks merkel tree as submitted by sender
    * computes total claim amount
    * -presale participation
    * -holders snapshot
    *
    * Transfers the total amount of token to the address
    *   
    */

    function claim(bytes32[] calldata _proof, bytes memory _leaf) external nonReentrant whenNotPaused {

        require(msg.sender != address(0), "ERROR: Invalid address");

        uint256 _nftHoldings = 0;
        bool _validNftClaim = false;

        (_validNftClaim, _nftHoldings) = nftClaimCheck(_proof, _leaf, msg.sender);
        
        uint256 _presaleAmount = getPresaleClaimComputation(msg.sender);
        uint256 _nftHolderAmount = getNFTHolderClaimComputation(_nftHoldings);

        uint256 _finalAmount = _presaleAmount + _nftHolderAmount; //compute final amount

        require(_finalAmount > 0, "ERROR: No tokens to claim.");
        require(claimed[msg.sender] < _finalAmount, "ERROR: Tokens already claimed.");

        _finalAmount = _finalAmount - claimed[msg.sender];
        
        require(maximToken.transfer(msg.sender, _finalAmount), "ERROR: Transfer failed");

        claimed[msg.sender] = _finalAmount;
        emit Claim(msg.sender, _finalAmount);
    }

    function nftClaimCheck(bytes32[] calldata _proof, bytes memory _leaf, address _address) public view returns (bool, uint256)  {

        require(msg.sender != address(0), "ERROR: Invalid address");
        address _account;
        uint256 _extractedHoldings;
        
        (_account, _extractedHoldings) = extractAddressAndUint(_leaf);

        require(_account == _address, "ERROR: Address is not the same.");

        bytes32 _leaf2 = keccak256(abi.encode(_account, _extractedHoldings));
        uint256 _nftHoldings = 0;
        bool _isValidClaim = MerkleProof.verify(_proof, nftHoldingsMerkleRoot, _leaf2);

        if (_isValidClaim) {
            _nftHoldings = _extractedHoldings;
        }
        
        return (_isValidClaim, _nftHoldings);
    }

    function extractAddressAndUint(bytes memory data) public pure returns (address, uint256) {
        // Ensure data length is at least 64 bytes (32 bytes for the address and 32 for the uint256)
        require(data.length >= 64, "Data length is insufficient");

        address extractedAddress;
        uint256 extractedUint;

        // Use abi.decode to extract the data
        (extractedAddress, extractedUint) = abi.decode(data, (address, uint256));

        return (extractedAddress, extractedUint);
    }

    /**
    * 
    * getNFTHolderClaimComputation
    * computes nftHolders claim
    *   
    */
    function getNFTHolderClaimComputation(uint256 _nftHoldings) public view returns (uint256) {
        
        if (_nftHoldings == 0)
            return 0; 

        (, uint256 totalSupply, ) = maximalsNftContract.getSupplyInfo();

        return (nftHoldersAllocation / totalSupply) * _nftHoldings;
    }

    /**
    * 
    * getPresaleClaimComputation
    * computes presale participants claim
    *   
    */
    function getPresaleClaimComputation(address _address) public view returns (uint256) {
        uint256 _amount = maximPresaleContract.getPurchases(_address);
        uint256 _totalFundsRaised = maximPresaleContract.getTotalFundRaised();
        uint256 _tokenUnitPrice = presaleAllocation / _totalFundsRaised;
        return _tokenUnitPrice * _amount ;
    }

    /**
    * 
    * getClaimComputation
    * gets presale participants claim and nftholders claim
    *   
    */

    function getClaimComputation(address _address, uint256 _nftHoldings) public view returns (uint256, uint256) {
        return (
            getPresaleClaimComputation(_address),
            getNFTHolderClaimComputation(_nftHoldings)
        );
    }

    /**
    * burns unclaimed tokens after presale period expires   
    */
    function burnUnclaimedTokens(address _burnAddress) public onlyOwner {
        uint256 _balance = maximToken.balanceOf(address(this));
        require(_balance > 0, "ERROR: No tokens to burn");
        maximToken.transfer(_burnAddress, _balance);
        emit TokensBuned(msg.sender, _balance);
    }

    // Function to deposit tokens into the contract
    function depositTokens(uint256 _amount) public onlyOwner {
        // Transfer tokens from the sender to this contract
        require(maximToken.transferFrom(msg.sender, address(this), _amount), "ERROR 412: Token transfer failed");
        // Emit event to log the deposit
        emit TokensDeposited(msg.sender, _amount);
    }
    
}

/*
* ***** ***** ***** ***** 
*/
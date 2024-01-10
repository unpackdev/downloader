/* SPDX-License-Identifier: MIT

Please go trough the Readme file.

*/
pragma solidity 0.8.10;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";

contract NFTContract is OwnableUpgradeable, ERC721EnumerableUpgradeable{

    using StringsUpgradeable for uint256;

    address public devs;
    uint256 public cost; 
    uint public maxSupply;
    uint whitelistLock;
    uint preSaleEnd;
    bool collectionIsReavealed;
    uint launchBlock;
    bool isRevealed;
    string public unRevealedURI;
    string public collection;
    


    /**
    whitelist to be use once with no me than 500 addresses
    */
    address[] public whitelist;

    /* 
    Fees per Nft.
    nftId => asset => amount
    this ways fees can be paid in any assets
    */
  
    // only one nft per account
    mapping(address => bool) public mintedPresale;
    mapping(address => uint) public minted;
    mapping(uint => string) private botUri;
    mapping(uint => uint) public mintedPhase;
    mapping(uint => uint) public maxMintPhase;
    // update
    uint public phase;
    uint public currentPhase;
    uint public MaxPerAccount;

    function initialize(
        address devs_,         
        uint256 price_,
        uint256 maxSupply_,
        uint launchBlock_,
        uint presaleLen_,
        uint devsQty,
        string memory name_,
        string memory symbol_,
        string memory unRevealedUri_,
        string memory collectionData_
        )public initializer {
         __ERC721_init(name_, symbol_);
         __Ownable_init();
         devs = devs_;
         cost = price_;
         maxSupply = maxSupply_;
         launchBlock = launchBlock_;
         preSaleEnd = launchBlock + presaleLen_; 
         unRevealedURI = unRevealedUri_;
         collection = collectionData_;
         mintDevsNft(devsQty);
    }

    function mint(uint256 _qty, address _to) external payable {
        require(totalSupply() < maxSupply,"Sold Out");
        require(_qty <= MaxPerAccount,"10 MAX");
        require(maxSupply >= totalSupply()+_qty, "Not enough left");
        require(block.number > launchBlock,"To soon!");
        uint256 yourPrice;

        if( block.number < preSaleEnd ){
            require(!mintedPresale[msg.sender],"Already minted presale");
            require(isWhitelist(msg.sender),"Must be white listed");
            require(_qty == 1,"Only one in presale");
            yourPrice = cost/4*3 * _qty;
            mintedPresale[msg.sender] = true; 
        }
        else{
           require(minted[msg.sender] < MaxPerAccount,"Maximum reached");
           require(mintedPhase[currentPhase] + _qty < maxMintPhase[currentPhase],"Maximum reached for phase");
           yourPrice = cost * _qty;
           minted[msg.sender] +=_qty;
           mintedPhase[currentPhase] +=_qty;
        }
     
        require(msg.value == yourPrice,"Price not right");
        payDevs();

        for(uint i = 0 ; i<_qty;i++){
            _safeMint(_to, totalSupply()+1);
        }
        
    }


    // update
    ///@notice phase change
    ///@param _cost the new price for this phase
    ///@param _phase the new price for this phase
    ///@param _phaseMaxMint max mintable in phase

    ///@dev to call once only. will lock after
    function updatePhase(uint256 _cost,  uint _phase, uint _phaseMaxMint ) external onlyOwner{
        cost = _cost;
        currentPhase = _phase;
        maxMintPhase[_phase] = _phaseMaxMint;

    }
        ///@dev to call once only. will lock after
    function updateLaunch(uint _preSaleEnd,  uint _launchBlock, uint256 _maxPer ) external onlyOwner{
        preSaleEnd = _preSaleEnd;
        launchBlock = _launchBlock;
        MaxPerAccount = _maxPer;
    }


    ///@notice Fill the whitelist with no more than 800 address
    ///@dev to call once only. will lock after
    function fillWhitelist(address[] memory accounts) external onlyOwner{
        require(whitelist.length <= 800,"To many whitelisted");
        whitelistLock =1;
        whitelist = accounts;
    }

    ///@notice check if an account is whitelisted.
    ///@dev if we dont want contract to mint we should use tx.origin
    function isWhitelist(address _account) public view returns(bool isWhiteListed) {
        for(uint256 i = 0; i < whitelist.length;i++){
            if(_account == whitelist[i]){
                return true;
            }
        }
        return false;     
    }

    ///@notice Fill the whitelist with no more than 800 address
    ///@param _uri ipfs foolder hash
    ///@dev to call once only. will lock after
    function reveal(string memory _uri) external onlyOwner{
        unRevealedURI = _uri;
    }

    /// @notice Return the token uri that was randomly atributed to that toke id
    /// @param _id the token id
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked('https://ipfs.io/ipfs/', unRevealedURI,'/', _id.toString(),'.json'));
    } 

    /// @notice For Opensea Royalties
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('https://ipfs.io/ipfs/', collection ));
    }

    function updateURI(string memory _ipfshash) external onlyOwner{
        collection = string(abi.encodePacked(_ipfshash));

    }

    /// @notice For Opensea Royalties
    /// @param _qty the quantity to mint
    /// @dev called upon deployment to resrve _qty
    function mintDevsNft(uint256 _qty) internal {
       for(uint i =0; i<_qty; i++){
           _safeMint(devs,totalSupply()+1);
       }
       minted[devs] = _qty;
    }

    /// @notice For Opensea Royalties
    /// @dev called upon deployment to resrve _qty
    function payDevs() internal {
        uint256 balance=address(this).balance;
        uint256 founder=balance/100*6;
        (bool success, ) = payable(0x5e0Ab6d9e9D51B94DedA5a11d8c2ea5c27410F70).call{
            value: founder
        }("");
        require(success);


         (bool success2, ) = payable(devs).call{
            value: balance-founder
        }("");
        require(success2);
    }

    receive() external payable{
        // allow contract to receive ETH
    }

}
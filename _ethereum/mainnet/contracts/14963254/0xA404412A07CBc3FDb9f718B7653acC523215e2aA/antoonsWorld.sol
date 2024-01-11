//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
                                                                                                   
/*                                                                                                                                                       
                            ,.%%%%%%%%%%%%%%%, ########                                     
                      #%  %%%%% %%%%%%%%%%%%%% #############(                               
                  #%%%%%%%%%%%%%%%%%%%%%%%%%%# ###########  %%%%%                           
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ##########  %%%%%%%%%%#                       
            ,%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  ########## /%%%%%%%%%%%%%%,                    
           (%%%%%%%%%%%%%%%%%%%%%%%%%%%%  ############. %%%%%%%%%%%%%%%%%%                  
         # (%%%%%%#  @@@@@  %%%%%%%%%% (##############/ %%%%%%%%%%%%%%%%%%%%                
       ####  %%%, @@@@@@@@@& %%%%%%%% (#################*  %%%%%%%%%%%%%%%%%%*              
      ######### (@@@@@@  @@@ %%%%%%%  ########################*    .%%%%%%%%%%%             
     ######### (@@@@@@& @@@@ %%%%%% (###############(/,###########. %%%%%%%%%%%(            
    #########* @@@@@@@ @@@@@ %%%. (#########,   (       ##########( %%%%%%%%%%%((           
   (######### #@@@@@@# @@@@/  ,#### ##,        /################### %%%%%%%%%%%(#(          
   ########## &@@@@@@ (@@@@ ##########  ###########################  %%%%%%%%%%(((*         
   ########## *@@@@@@ @@@@ .##########################(/(########### #%%%%%%%%(((((         
  /########### @@@@@@@@@@ ,####################   @@. @@@@@  ########  %%%%%%%(((((         
  /############ &@@@@@@  ##################  &@@@@@@@@ .@@@@@ #########  *%%%((((((         
   ##############(   *################(   @@@@@@@@@@@@@@  @@@ (#############/     .         
   #.  .##/  % %   ##############*  ,@@@@@  @@@@@@@@@@@@@@@@  #############((((((((         
   (%%%%% @@@@@ @@@@@%        (@@@@@@@@@@@@@. @@@@@@@@@@@@& ##############((((((((*         
    %%%% &@@@@@@ &@@@@@@@@@@ (@@@@@@@@@@@@@@@@@  @@@@@@@. ###############(((((((((          
     %%%, @@@@@@@  @@@@@@@@@@% @@@@@@@@@@@@@@@@@@@&    /###############((((((((((           
      %%%% %@@@@@@& @@@@@@@@@@@* @@@@@@@@@@@@@@@@@  #################(((((((((((.           
       %%%%%  /@@@@@. @@@@@@@@@@@@  @@@@@@@@@.  ###################((((((((((((             
         %%%%%%%/   @@% *@@@@@@@@@@@@@    .######################(((((((((((((              
          #%%%%%%%%%%%%%(.       ,#%%  ##/ #%%%%*   ##########((((((((((((((/               
            #%%%%%%%%%%%%%%%%%%%%%%%%% /#, %%%%%%%%%% ,#####(((((((((((((((                 
               %%%%%%%%%%%%%%%%%%%%%%%% (#* %%%%%%%%%% /((((((((((((((((*                   
                 ,#%%%%%%%%%%%%%%%%%%%%% *##  %%%%%#(( /((((((((((((((                      
                     (((((((#%%%%%%%%%%%%  ((((      /((((((((((((,                         
                         /(((((((((((((((((,../...   ,((((((((                              
                               .(((((((((((((((((((((((             
                                                            
                                                        Goldmember#0001 @ Normie Labs
*/                            

import "./console.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";

contract AntoonsWorld is ERC721A, IERC2981, Ownable {
    // collection details
    uint256 public constant PRICE = 0.15 ether;

    uint256 public constant MAX_SUPPLY = 250; 
    uint256 public constant MAX_MINTS_PER_ALLOW_LIST = 1;
    uint256 public constant MAX_MINTS_PER_PUBLIC_MINT = 1;
    uint256 public constant MAX_MINTS_PER_STAFF_MINT = 2;

    // merkle tree
    bytes32 public merkleRoot;
    bytes32 public staffMerkleRoot;

    // variables and constants
    string public baseURI = "toon://sorryDetective/";
    bool public isAllowlistMintActive = false;
    bool public isStaffMintActive = false;
    bool public isPublicMintActive = false;
    mapping(address => uint256) public allowlistMintsPerAddress;
    mapping(address => uint256) public staffMintsPerAddress;
    mapping(address => uint256) public publicMintsPerAddress;
    address public ownerWallet;
    uint256 private royaltiesPercentage;
    address private royaltiesWallet;

    constructor(
        address _ownerWallet,
        address _royaltiesWallet,
        bytes32 _merkleRoot,
        bytes32 _staffMerkleRoot,
        string memory _URI
    ) 
    ERC721A("Antoons World", "TOON") 
    {
        ownerWallet = _ownerWallet;
        royaltiesWallet = _royaltiesWallet;
        merkleRoot = _merkleRoot;
        staffMerkleRoot = _staffMerkleRoot;
        baseURI = _URI;

        setRoyaltiesPercentage(10);
    }

    function allowlistMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
    {
        // active check
        require(isAllowlistMintActive, "TOON: allowlist mint is not active");
        // price check
        require(msg.value == _quantity * PRICE, "TOON: insufficient amount paid");
        // supply check
        require(
            _quantity + totalSupply() < MAX_SUPPLY,
            "TOON: not enough remaining to mint"
        );
        // allowlist max minting check
        require(
            allowlistMintsPerAddress[msg.sender] + _quantity <=
                MAX_MINTS_PER_ALLOW_LIST,
            "TOON: max mint for address met"
        );

        // merkle verification
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "TOON: not in allowlist"
        );

        // mint and update mapping
        allowlistMintsPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function staffMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
    {
        // active check
        require(isStaffMintActive, "TOON: staff mint is not active");
        // price check
        require(msg.value == _quantity * PRICE, "TOON: insufficient amount paid");
        // supply check
        require(
            _quantity + totalSupply() < MAX_SUPPLY,
            "TOON: not enough remaining to mint"
        );
        // staff max minting check
        require(
            staffMintsPerAddress[msg.sender] + _quantity <=
                MAX_MINTS_PER_STAFF_MINT,
            "TOON: max mints per allowlist exceeded"
        );

        // merkle verification
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, staffMerkleRoot, leaf),
            "TOON: not staff"
        );

        // mint and update mapping
        staffMintsPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable {
        // active check
        require(isPublicMintActive, "TOON: public mint is not active");
        // price check
        require(msg.value == _quantity * PRICE, "TOON: insufficient amount paid");
        // supply check
        require(
            _quantity + totalSupply() < MAX_SUPPLY,
            "TOON: not enough remaining to mint"
        );
        // allowlist max minting check
        require(
            publicMintsPerAddress[msg.sender] + _quantity <=
                MAX_MINTS_PER_PUBLIC_MINT,
            "TOON: max mints per address exceeded"
        );

        // mint
        publicMintsPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function ownerMint(uint256 _quantity) external onlyOwner {
        // supply check
        require(
            _quantity + totalSupply() < MAX_SUPPLY,
            "TOON: not enough remaining to mint"
        );

        // mint to first party wallet
        _safeMint(ownerWallet, _quantity);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setStaffMerkleRoot(bytes32 root) external onlyOwner {
        staffMerkleRoot = root;
    }

    function setOwnerWallet(address _newWallet) external onlyOwner {
        ownerWallet = _newWallet;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleAllowlistMint() public onlyOwner {
        isAllowlistMintActive = !isAllowlistMintActive;
    }
        
    function toggleStafflistMint() public onlyOwner {
        isStaffMintActive = !isStaffMintActive;
    }

    function togglePublicMint() public onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "TOON: nothing to withdraw");

        payable(ownerWallet).transfer(address(this).balance);
    }

    function setRoyaltiesPercentage(uint256 _newRoyalties) public onlyOwner {
        royaltiesPercentage = _newRoyalties;
    } 

    function setRoyaltiesWallet(address _newWallet) public onlyOwner {
        royaltiesWallet = _newWallet;
    }

        // ERC165
    function supportsInterface(bytes4 _interfaceId) public view override(ERC721A, IERC165) returns (bool) {
      return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    // IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
      require(_exists(_tokenId), "TOON: Token does not exist"); 
      royaltyAmount = (_salePrice / 100) * royaltiesPercentage;
      return (royaltiesWallet, royaltyAmount);
    }
}

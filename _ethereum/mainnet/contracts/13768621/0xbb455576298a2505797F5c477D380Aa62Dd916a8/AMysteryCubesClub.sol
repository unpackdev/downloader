/////////////////////////////////////
//|________________________________//
// SPDX-License-Identifier: MIT     
//|________________________________//                                 
// A Mystery Cubes Club!            
//|________________________________// 
// May we choose loving expression // 
// May we express creation forever // 
// May a light penetrate eternity  // 
// May art resound through beauty  //
// May we find the sight and voice //
// of our deepest creative selves  //
//|________________________________//                                 
//| with love as my intention,     //           
// 🧞✨💚 Divenie the Blessed 
//|_______________________________//                                 
//|______________________________//
//|_____________________________//

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol"; 

contract MYSC is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string public baseURI = "ipfs://QmVirC6GTvMwWAqyoy5vYNXPDqtS5t4pJyCxW4ZfnaoXMY/";  
    uint256 public constant price = 25000000000000000;   // 0.025 ETH  
    uint256 public constant max_Cubes = 412; ///@dev Minter mints < max_Cubes = last mint is 411  
    uint public cubesReserve = 22; ///@dev dev supply  
    uint public ticketsCount = 22; ///@dev initial ticket counter must start at reserve 
    uint public maxTickets = 412; ///@dev assets are 0-411, tickets are 1-412

    mapping(address => uint256) public ticketbalance; 
    event ticketChange(address _by, uint _status);
    event mintSuccess(address); 

    bool public ticketSaleIsActive = false; 
    bool public mintingSaleIsActive = false; 

    mapping(uint => string) public member_Name; ///@notice Club Member Name    
    mapping(uint => string) public cube_Quote; ///@notice Cube Wisdom Quote 
    mapping(uint => string) public art_Path; ///@notice Cube Art Path 
    mapping(uint => string) public metaverse_Path; /// @notice Metaverse Integration Ready     
    event cubeNameChange(address _by, uint _tokenId, string _name);
    event cubeQuoteChange(address _by, uint _tokenId, string _quote);
    event cubeArtChange(address _by, uint _tokenId, string _art_path);
    event cubeMetaverseChange(address _by, uint _tokenId, string _quote);

    constructor(string memory _URI) ERC721("A Mystery Cubes Club!", "MYSC") {
        //setbaseURI(_URI);
 
        //ticketSaleIsActive = !ticketSaleIsActive;  
        //mintingSaleIsActive = !mintingSaleIsActive;  
    }   
    function setbaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    ///////////////
    // TICKETS ///  
    /////////////
    
    function setTicketSaleIsActive() external onlyOwner {
        ticketSaleIsActive = !ticketSaleIsActive; 
    }
    function buy_Ticket() public payable {  
        require(ticketSaleIsActive, "Sale must be active to acquire ticket"); 
        require(ticketsCount < maxTickets, "There are no more tickets"); 
        require(msg.value == price, "Not enough Ether sent"); 
        if (ticketsCount < maxTickets) { 
            ticketsCount++; 
            ticketbalance[msg.sender]++;
            emit ticketChange(msg.sender, ticketbalance[msg.sender]);   
        }
    } 
    function get_My_Ticket_Balance() public view returns(uint) {
        return ticketbalance[msg.sender]; 
    } 

    ///////////////
    // MINTING ///
    /////////////

    function setMintingSaleIsActive() external onlyOwner {
        mintingSaleIsActive = !mintingSaleIsActive; 
    }
    ///@dev main minting function 
    function mint_Cubes(uint amount) public { 
        require(mintingSaleIsActive, "Minting is not active yet");  //is minting active
        _mint_With_Tickets(msg.sender, amount); 
    } 
    ///@dev internal mint with number of tickets function 
    function _mint_With_Tickets(address account, uint256 amount) internal { //user, qty 
        require(amount > 0, "Invalid amount"); ///@dev qty cannot be less than 1 
        require(amount <= ticketbalance[account], "Not enough tickets!"); 
        ticketbalance[account] -= amount; ///@dev subtract amount of tickets from users account balance. 
        for (uint256 i = 0; i < amount; i++) { //from the qty user has requested to mint, run minter 
            _mint();  
        }
    }
    function _mint() internal {
        require(totalSupply() <= max_Cubes, "Critical, mint would exceed max supply of Cubes, please contact dev immediately"); 
        uint mintIndex = totalSupply();
        if (totalSupply() < max_Cubes) { ///@dev adds until the last asset 
            _safeMint(msg.sender, mintIndex);
        }
        emit mintSuccess(msg.sender); //event
    }
    
    ///////////////
    // SET     ///
    /////////////

    ///@dev metaverse_Path
    function setMetaversePath(uint _tokenId, string memory _metaverse_path) public {
        require(ownerOf(_tokenId) == msg.sender, "Hey, your wallet doesn't own this cube!");
        require(sha256(bytes(_metaverse_path)) != sha256(bytes(metaverse_Path[_tokenId])), "Same as current");
        metaverse_Path[_tokenId] = _metaverse_path;
        emit cubeMetaverseChange(msg.sender, _tokenId, _metaverse_path);   
    }
    ///@dev art_Path
    function setArtPath(uint _tokenId, string memory _art) public {
        require(ownerOf(_tokenId) == msg.sender, "Hey, your wallet doesn't own this cube!");
        require(sha256(bytes(_art)) != sha256(bytes(art_Path[_tokenId])), "Same as current");
        art_Path[_tokenId] = _art;
        emit cubeArtChange(msg.sender, _tokenId, _art);   
    }
    ///@dev member_Name
    function setMemberName(uint _tokenId, string memory _name) public {
        require(ownerOf(_tokenId) == msg.sender, "Hey, your wallet doesn't own this cube!");
        require(sha256(bytes(_name)) != sha256(bytes(member_Name[_tokenId])), "Same as current");
        member_Name[_tokenId] = _name;
        emit cubeNameChange(msg.sender, _tokenId, _name);   
    }
    ///@dev cube_Quote
    function setCubeQuote(uint _tokenId, string memory _quote) public {
        require(ownerOf(_tokenId) == msg.sender, "Hey, your wallet doesn't own this cube!");
        require(sha256(bytes(_quote)) != sha256(bytes(cube_Quote[_tokenId])), "Same as current");
        cube_Quote[_tokenId] = _quote;
        emit cubeQuoteChange(msg.sender, _tokenId, _quote);   
    }
    
    ///////////////
    // GET     ///
    /////////////

    function getMetaversePath(uint _tokenId) public view returns( string memory ){
        require( _tokenId < totalSupply(), "Choose a cube within range" );
        return metaverse_Path[_tokenId];
    }
    function getCubeData(uint _tokenId) public view returns( string memory, string memory, string memory){
        require( _tokenId < totalSupply(), "Choose a cube within range" );
        return(member_Name[_tokenId], cube_Quote[_tokenId], art_Path[_tokenId]);
    }

    ///////////////
    // GET ALL ///
    /////////////
    
    ///@dev get all names in all cubes  
    function allName() public view returns( string[] memory ){
        uint cubecount = totalSupply();
        string[] memory result_Name = new string[](cubecount);
        uint256 index;
        for (index = 0; index < cubecount; index++) {
            result_Name[index] =  member_Name[index];
        }
        return result_Name; 
    }

    ///@dev get all quotes in all cubes  
    function allCubeQuote() public view returns( string[] memory ){
        uint cubecount = totalSupply();
        string[] memory result = new string[](cubecount);
        uint256 index;
        for (index = 0; index < cubecount; index++) {
            result[index] =  cube_Quote[index];
        }
        return result; 
    }
    ///@dev get all metaverse links in all cubes  
    function allMetaverse() public view returns(string[] memory){
        uint cubecount = totalSupply();
        string[] memory result_Metaverse = new string[](cubecount);   
        uint256 index;
        for (index = 0; index < cubecount; index++) {
            result_Metaverse[index] =  metaverse_Path[index];         
        } 
        return (result_Metaverse); 
    }

    ///////////////
    // OWNER   ///
    /////////////

    /// Withdraw contract balance to creator (mnemonic seed address 0) // from Bauhaus
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }    
    ///@dev Owner reserve NFT function 
    function reserveCubes(address _to, uint256 _reserveAmount) public onlyOwner { 
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= cubesReserve, "Not enough reserve left"); 
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        cubesReserve = cubesReserve.sub(_reserveAmount);
    }

    ///////////////
    // OVERRIDES /
    /////////////
    
    function tokenURI(uint256 tokenId) ///@dev Bauhaus TokenURI 
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
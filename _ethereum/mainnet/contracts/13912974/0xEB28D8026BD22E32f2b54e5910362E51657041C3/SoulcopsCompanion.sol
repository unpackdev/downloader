// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    MMMMMMMMMM0;...,:dKWMMMMMMMMMMMMMMMMMK:...;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc...,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMMMMMMMM0;......,xNMMMMMMMMMMMMMMMMK:...;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc...,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xxxkKMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMMMMMMMMNkl,.....'dNMMMMMMMMMMMMMMMK:...;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc...,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl...'xWMMMMMMMMMMMMMMMMMMMMMMMMM
    NXNMMWXKKKK0o'.......oXMMMMMMMMMMMMMMK:...;0MMMMMMWXXXXNMMWNXKKKKXNMMMMMMMMMNo....dWMWNXK0KKXWMMMMMMMMMMMMMMMMWNKKKKXNWMMNXXXXNMMMMXc...,OMMMMMMMMMMMWNXK0KKXWMMMMMMMMMNl...'dXXXXNWMMMMMMWNXKK0KKXNWMMM
    :,c0Xl,'''''..........lXMMMMMMMMMMMMMK:...;0MMMMMWk;,,;x0dc;,'''',:lxKWMMMMMNo....oOdc;,'''',:oONMMMMMMMMMWXko:;,''',;cdOd,,,;xWMMMXc...,OMMMMMMMMXOoc;,'''',:lxKWMMMMMNl....',;;;c0MMMN0dl;,''''',;:lxK
    lcdKXxc::,.....,dd,....lKMMMMMMMMMMMMK:...;0MMMMMWx'...''...'','.....,oKWMMMNo....'....'''......c0WMMMMMMXd;.....',,'...''....dWMMMXc...,OMMMMMMXx;....,;:;,'...,l0WMMMNl.....'''':OMMKl'....,;;;,'...cK
    NKKXXK00k:....,xWWk;....cKMMMMMMMMMMMK:...;0MMMMMWx'.....;ok0KKKOd:....;OWMMNo.....'cxOKKKOd;....;0MMMMW0:....;oOKXXKOd:......dWMMMXc...,OMMMMMKc...'lkKNNNX0d;...;kWMMNl....oKKKKXWMXl...'o0XXNNXKOxxKM
    :,,,,,,,'....,kWMMWO;....:0MMMMMMMMMMK:...;0MMMMMWx'....lKWMMMMMMMXo'...:0MMNo....,xNMMMMMMMKc....oNMMMXc....lKWMMMMMMMXd'....dWMMMXc...,OMMMMXc...,kWMMMMMMMW0:...;0MMNl...'xWMMMMMMK:...,xXWWMMMMMMMMM
    c;;;;;'.....;OWMMMMW0:....:0WMMMMMMMMK:...;0MMMMMWx'...:KMMMMMMMMMMXl....dWMNo....oNMMMMMMMMWx'...lXMMMk,...:KMMMMMMMMMMNl....dWMMMXc...,OMMMMk'...lXXX0Okxdoc:,....dWMNl...'xWMMMMMMNx'....,:lodxk0KNMM
    NKK00x,....;OWMMMMMMW0:....;OWMMMMMMMK:...;0MMMMMWx'...lNMMMMMMMMMMWd....oNMNo....dWMMMMMMMMMk'...lXMMWx'...lXMMMMMMMMMMWd....dWMMMXc...,OMMMWx'...,;;,'....',;clodxKWMNl...'xWMMMMMMMW0o:,.........,:xX
    :;,,,'....:0WMMMMMMMMMKc....,kWMMMMMMK:...;0MMMMMWx'...:0MMMMMMMMMMKc...'xWMNo....dWMMMMMMMMWk'...lXMMMO,...;0MMMMMMMMMMXc....dWMMMXc...,OMMMMO,....,clodxO0KXNWMMMMMMMNl...'xWMMMMMMMMMWNK0kxdolc,....c
    c;,......cKWMMMNXXNWMMMKc....,o0NWMMMK:...,OMMMMMWx'....c0WMMMMMMW0c....cKMMNo....dWMMMMMMMMMk'...cXMMMXo....:OWMMMMMMW0l.....dWMMMXc...'kMMMMNo....c0WMMMMMMMWXKNMMMMMNl....dWMMMMMMMWXNMMMMMMMMW0c...'
    WN0:....cKMMMWk:,,:kNMMMXl.....':lOWMXl....:k00KNWx'.....'cxkO0Oxl,....c0WMMNo....dWMMMMMMMMMk'...lXMMMMXl'...'cdkOOkdl,......dWMMMNo....:x00KNXo'...,cdkO0Okxl;'cOWMMMWx'...,dO0Ok0WNx;:ldkO0K00ko,...;
    MMNd'..lKMMMMKc....:KMMMMXd,......dWMMKl.......:0Wx'...,;...........':xXMMMMNo....dWMMMMMMMMMk'...lXMMMMMNkc'...........;;....dWMMMMXo'......;OMNOl,.............;xNMMMMNd,.....'..;OO:.......''.....,l0
    MMMNkcdXMMMMMWOc;;cOWMMMMMWXkl:;,;xWMMMNOoc;;;;oKWx'...lKOdc:;;;;clx0NMMMMMMWk:::cOWMMMMMMMMM0l:::xNMMMMMMMN0xoc:;;;:cokXOl::cOWMMMMMN0dc;;;;l0MMMWKkdl:;;,;;:ldOXWMMMMMMWKxl:;;;:cdKNKkdoc:;;;;;:cokKWM
    MMMMMWWMMMMMMMMWNNWMMMMMMMMMMMWNXXNMMMMMMMWNNNNWMWx'...lNMMWNNXNNWMMMMMMMMMMMWWWWWWMMMMMMMMMMWWWWWWMMMMMMMMMMMMWNNNNNWMMMMWWWWWMMMMMMMMMWNNNNWMMMMMMMMMWNXXNNWMMMMMMMMMMMMMMWNNXNNWMMMMMMMWWNNXNNWWMMMMM
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/  

import "./ERC721EnumerableM.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract SoulcopsCompanion is ERC721EnumerableM, Ownable {
    using Strings for uint256;
    enum Stage {
        Shutdown,
        Aidrop,
        Publicsale
    }

    Stage public stage;
    bytes32 public root;
    uint256 public constant MAX_PER_TX = 6; // 5 maximum, use 6 reduce aritmatic gas
    uint256 public constant MAX_AIRDROP = 3000;
    uint256 public constant TOTAL = 10000;
    uint256 public PRICE;
    uint256 public airdropQtyMinted;
    
    mapping(address => uint256) public addressAirdopMinted;

    string private _contractURI;
    string private _baseTokenURI;
    string private _defaultTokenURI;

    address SOULCOPS_WALLET = 0x71D54d6Dd26339B4d69C5cd922C4846aC6fb5E95;

    constructor(
        string memory defaultTokenURI,
        bytes32 merkleroot
    ) 
        ERC721M("Soulcops Companion", "COMPANION")  {
        _defaultTokenURI = defaultTokenURI;
        root = merkleroot;
    }
    
    function setPrice(uint256 _price) external onlyOwner {
        require(_price>=0, "Price cannot negative.");
        PRICE = _price;
    }

    function setMerkleRoot(bytes32 merkleroot) external onlyOwner {
        root = merkleroot;
    }

    function airdropMint(uint256 count, uint256 allowance, bytes32[] calldata proof) external {
        uint256 totalSupply = _owners.length;
        require(_verify(_leaf(_msgSender(), allowance), proof), "Invalid merkle proof.");
        require(stage == Stage.Aidrop, "The airdop not active.");
        require(airdropQtyMinted + count <= MAX_AIRDROP, "Minting would exceed the airdrop allocation.");
        require(totalSupply + count <= TOTAL, "Minting would exceed the sale allocation.");
        require(addressAirdopMinted[_msgSender()] + count <= allowance, "You can not mint exceeds maximum NFT.");
         
        addressAirdopMinted[_msgSender()] += count;

        for (uint i = 0; i < count; i++) {
            airdropQtyMinted++;
            _mint(_msgSender(), totalSupply + i);
        }
    }
    
    // public mint
    function publicMint(uint256 count) external payable {
        uint256 totalSupply = _owners.length;
        require(stage == Stage.Publicsale, "The sale not active.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        require(totalSupply + count <= TOTAL, "Minting would exceed the sale allocation.");
        require(PRICE * count == msg.value, "ETH sent not match with total purchase.");

        for (uint i = 0; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    // get all token by owner addresss
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function withdraw() external onlyOwner {
        Address.sendValue(payable(SOULCOPS_WALLET), address(this).balance);
    }

    // get address minted count
    function airdopMintedCount(address addr) external view returns (uint256) {
        return addressAirdopMinted[addr];
    }
    
    // change stage airdrop, and shutdown
    function setStage(Stage _stage) external onlyOwner{
        require(_stage!=Stage.Publicsale, "Public sale must with set price.");
        stage = _stage;
    }

    // change stage to public mint and set price
    function setPublicSale(uint256 _price) external onlyOwner {
        stage = Stage.Publicsale;
        PRICE = _price;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }
    
    function setDefaultTokenURI(string calldata URI) external onlyOwner {
        _defaultTokenURI = URI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // get tokenURI by index, add default base uri
    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
    }


    function _leaf(address account, uint256 allowance)internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account,allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, root, leaf);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    
}
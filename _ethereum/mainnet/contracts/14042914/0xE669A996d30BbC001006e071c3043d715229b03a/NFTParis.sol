import "./ERC1155.sol";
import "./Ownable.sol";

contract NFTParis is ERC1155, Ownable {
    constructor(string memory uri) ERC1155(uri) {
        openMints[0] = true;
    }

    mapping(uint256 => bool) public openMints;

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function safeMint(uint256 id, bytes memory data) public {
        require(openMints[id] == true, "Unauthorized Mint");
        require(balanceOf(msg.sender, id) < 1, "You already have one");
        _mint(msg.sender, id, 1, data);
    }

    function openMint(uint256 id) public onlyOwner {
        openMints[id] = true;
    }

    function closeMint(uint256 id) public onlyOwner {
        openMints[id] = false;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }
}

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract NFTArtGen is ERC1155, Ownable {
    string public name;
    string public symbol;
    string public baseUri;

    uint256 public cost = 0.05 ether;
    uint32 public maxPerMint = 5;
    uint32 public maxPerWallet = 20;
    uint32 public supply = 0;
    uint32 public totalSupply = 0;
    bool public open = false;

    uint32 private commission = 49; // 4.9%
    address payable commissionAddress =
        payable(0x460Fd5059E7301680fA53E63bbBF7272E643e89C);

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        uint32 _totalSupply,
        uint256 _cost,
        bool _open
    ) ERC1155(_uri) {
        baseUri = _uri;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        cost = _cost;
        open = _open;
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setmaxPerWallet(uint32 _max) public onlyOwner {
        maxPerWallet = _max;
    }

    function setMaxPerMint(uint32 _max) public onlyOwner {
        maxPerMint = _max;
    }

    function _mint(address to, uint32 count) internal {
        if (count > 1) {
            uint256[] memory ids = new uint256[](uint256(count));
            uint256[] memory amounts = new uint256[](uint256(count));

            for (uint32 i = 0; i < count; i++) {
                ids[i] = supply + i + 1; // Start at 1
                amounts[i] = 1;
            }

            _mintBatch(to, ids, amounts, "");
        } else {
            _mint(to, supply + 1, 1, "");
        }

        supply += count;

        (bool success, ) = payable(commissionAddress).call{
            value: (msg.value * commission) / 1000
        }("");
        require(success);
    }

    function mint(uint32 count) external payable {
        require(count > 0, "Mint at least one.");
        require(count <= maxPerMint, "Max mint reached.");
        require(msg.value >= cost * count, "Not enough fund.");
        require(supply + count <= totalSupply, "Mint sold out");
        require(open == true, "Mint not open");
        require(
            balanceOf(msg.sender) + count <= maxPerWallet,
            "Max total mint reached"
        );

        _mint(msg.sender, count);
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i <= supply; i++) {
            if (balanceOf(account, i) == 1) {
                balance += 1;
            }
        }
        return balance;
    }

    function airdrop(address[] calldata to) public onlyOwner {
        for (uint32 i = 0; i < to.length; i++) {
            require(1 + supply <= totalSupply, "Limit reached");
            _mint(to[i], 1);
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId <= supply, "Not minted yet");

        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }
}

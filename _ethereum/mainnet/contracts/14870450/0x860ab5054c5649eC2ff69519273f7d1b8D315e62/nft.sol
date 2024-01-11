//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract SabotenPlanet is ERC721A, Ownable, ReentrancyGuard {
    string private baseURI = "";
    string public constant baseExtension = ".json";
    string private notRevealedUri;
    uint256 public MAX_SUPPLY = 10000;
    bool public paused = false;
    bool public revealed = false;
    uint256 public price = 0.08 ether;
    bytes32[] public roots;
    uint256[] public maxmints = [1, 2];
    uint256 public presaleEndTime;
    uint256 public presaleStartTime;

    event addedToWhitelist(address indexed _by, address _address, uint256 role);
    event whitelistUpdated(
        address indexed _by,
        address[] newWhitelist,
        uint256 typeOfWL
    );
    event Mint(address indexed _to, uint256 _amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        bytes32[] memory _initRoots,
        uint256 _presaleStartTime,
        uint256 _duration
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleStartTime + _duration;
        roots = _initRoots;
    }

    function presaleMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        address _caller = msg.sender;
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        bool isWL = isWhitelisted(_caller, _merkleProof);
        uint256 callerBalance = balanceOf(msg.sender);
        uint256 userMaxMint = maxMintAmount(_caller, _merkleProof);
        uint256 totalMintCost = price * _amount;
        require(block.timestamp > presaleStartTime, "Sale Has Not Started Yet");
        require(block.timestamp < presaleEndTime, "Presale has Ended");
        if (_caller != owner()) {
            require(isWL == true, "user is not whitelisted");
            require (callerBalance + _amount <= userMaxMint,'Exceeds Maximum Allowed During Whitelist');
            require(totalMintCost == msg.value, "Invalid funds provided");
        }
        _safeMint(_caller, _amount);
    }

    function mint(uint256 _amount) external payable {
        address _caller = msg.sender;
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        uint256 mintCost = price;
        uint256 totalMintCost = mintCost * _amount;
        require(block.timestamp > presaleEndTime, "Presale has not ended yet");
        if (_caller != owner()) {
            require(totalMintCost == msg.value, "Invalid funds provided");
        }

        _safeMint(_caller, _amount);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    function isWhitelisted(address _user, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < roots.length; i++) {
            bytes32 root = roots[i];
            bytes32 leaf = keccak256(abi.encodePacked(_user));
            if (MerkleProof.verify(_merkleProof, root, leaf)) {
                return true;
            }
        }
        return false;
    }

    function whichWhitelist(address _user, bytes32[] calldata _merkleProof)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < roots.length; i++) {
            bytes32 root = roots[i];
            bytes32 leaf = keccak256(abi.encodePacked(_user));
            if (MerkleProof.verify(_merkleProof, root, leaf)) {
                return i;
            }
        }
        return 100000;
    }

    function maxMintAmount(address _user, bytes32[] calldata _merkleProof)
        public
        view
        returns (uint256)
    {
        uint256 maxMint;
        if (block.timestamp < presaleEndTime) {
            if (isWhitelisted(_user, _merkleProof)) {
                uint256 typeOfWL = whichWhitelist(_user, _merkleProof);
                maxMint = maxmints[typeOfWL];
            }
        } else {
            maxMint = maxmints[1];
        }
        return maxMint;
    }

    function currentPrice() public view returns (uint256) {
        return price;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        _withdraw(msg.sender);
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function _withdraw(address _caller) private {
        payable(_caller).transfer(address(this).balance);
    }

    function setmaxMintAmounts(uint256[] calldata _newMaxMints) public onlyOwner {
        maxmints = _newMaxMints;
    }

    function setupOS() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function updateMaxSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function airdrop(address _to, uint256 _amount) public onlyOwner {
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == msg.sender, "No contracts");
        _safeMint(_to, _amount);
    }

    function airDropAll(address[] calldata _addressList, uint256 amount)
        public
        onlyOwner
    {
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + amount, "Exceeds max supply");
        require(amount > 0, "No 0 mints");
        require(tx.origin == msg.sender, "No contracts");
        for (uint256 i = 0; i > _addressList.length; i++) {
            address currRecipient = _addressList[i];
            _safeMint(currRecipient, amount);
        }
    }

    function updateRootList(bytes32[] calldata _newRootList) public onlyOwner {
        roots = _newRootList;
    }

    function addRootToList(bytes32 _rootToAdd) public onlyOwner {
        roots.push(_rootToAdd);
    }

    function extendSaleTimes(uint256 _newStart,uint256 _duration) public onlyOwner {
        presaleStartTime = _newStart;
        presaleEndTime = _newStart + _duration;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }
}

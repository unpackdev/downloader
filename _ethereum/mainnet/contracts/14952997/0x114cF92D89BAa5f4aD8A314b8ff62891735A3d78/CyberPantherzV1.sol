pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
//     ______      __              ____              __  __                            ___
//    / ____/_  __/ /_  ___  _____/ __ \____ _____  / /_/ /_  ___  _________     _   _<  /
//   / /   / / / / __ \/ _ \/ ___/ /_/ / __ `/ __ \/ __/ __ \/ _ \/ ___/_  /    | | / / /
//  / /___/ /_/ / /_/ /  __/ /  / ____/ /_/ / / / / /_/ / / /  __/ /    / /_    | |/ / /
//  \____/\__, /_.___/\___/_/  /_/    \__,_/_/ /_/\__/_/ /_/\___/_/    /___/    |___/_/
//       /____/
contract CyberPantherzV1 is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    Counters.Counter private newtonSupply;
    Counters.Counter private davisSupply;
    Counters.Counter private hamptonSupply;

    bool public paused;
    bool public revealed;
    bool public presale;

    uint256 public constant maxSupply = 8888;
    uint256 public constant newtonMaxSupply = 3333;
    uint256 public constant davisMaxSupply = 3333;
    uint256 public constant hamptonMaxSupply = 2222;

    uint256 public cost = 0.03 ether;

    uint256 public maxMintAmountPerTx = 30; 
    uint256 public maxPerPresaleAddress = 9; 
    uint256 public maxPerFreesaleAddress = 1; 
    uint256 public reserveCount;
    uint256 public reserveLimit = 888;
    
    address public constant artistAddress = 0xF81e259107b9C2D383C8753e395E30AE48666941;
    address public constant devAddress = 0x9C0aC9D88DE0c9AF72Cb7d5Cc4929289110E5BE9;
    address public constant dev2Address = 0x9D9Df0C57F5D4C54492F1486e0c4af5d006A6967;
    address public constant eventsAddress = 0x4a4Fda747E0DFD438fE77b198028838076A48118;
    address public constant investorAddress = 0xBAE0f07DE520Ebdf520C35364De4C15EBE72d662;
    address public constant contributersAddress = 0x0B2b5A6B723524BBD8e463246ea45FD401c0E079;
    address public constant communityAddress = 0xb686c06a9667e48e1ACc4c88a7d9727B6EE2c47a;

    bytes32 public presaleMerkle;
    bytes32 public freesaleMerkle;

    string public uriPrefix;
    string public uriSuffix;
    string public uriHidden;

    mapping(address => uint256) public presaleClaimed;
    mapping(address => uint256) public freesaleClaimed;

    mapping(uint256 => uint256) public tokenIdsToBase;

    constructor(string memory _uriHidden, bytes32 _presaleMerkle, bytes32 _freesaleMerkle)
        ERC721("CyberPantherzV1", "CPZV1")
    {
        uriHidden = _uriHidden;
        presaleMerkle = _presaleMerkle;
        freesaleMerkle = _freesaleMerkle;
        uriPrefix = "UNREVEALED";
        uriSuffix = ".json";
        reserveCount = 0;
        paused = true;
        revealed = false;
        presale = true;
    }

    modifier mintCompliance(uint256[3] memory mintAmounts) {
        uint256 mintCount = (mintAmounts[0] + mintAmounts[1] + mintAmounts[2]);
        require(!paused, "The sale is paused.");
        require(mintCount > 0, "Mint count must be greater than 0.");
        require(
            mintCount <= maxMintAmountPerTx,
            "Invalid mint amount. Too high."
        );
        require(
            supply.current() + mintCount <= maxSupply,
            "Max supply exceeded."
        );
        require(
            supply.current() + mintCount <= maxSupply - (reserveLimit - reserveCount),
            "Max supply + reserve exceeded."
        );
        require(
            newtonMaxSupply >= newtonSupply.current() + mintAmounts[0],
            "Not enough Newtons left."
        );
        require(
            davisMaxSupply >= davisSupply.current() + mintAmounts[1],
            "Not enough Davis left."
        );
        require(
            hamptonMaxSupply >= hamptonSupply.current() + mintAmounts[2],
            "Not enough Hamptons left."
        );
        _;
    }

    function mintPresale(
        address account,
        uint256[3] memory mintAmounts,
        bytes32[] calldata merkleProof
    ) public payable mintCompliance(mintAmounts) {
        bytes32 node = keccak256(
            abi.encodePacked(account, maxPerPresaleAddress)
        );
        uint256 mintCount = (mintAmounts[0] + mintAmounts[1] + mintAmounts[2]);
        require(presale, "No presale minting currently.");
        require(msg.value >= cost * mintCount, "Insufficient funds.");
        require(
            presaleClaimed[account] + mintCount <= maxPerPresaleAddress,
            "Exceeds max mints for presale."
        );
        require(
            MerkleProof.verify(merkleProof, presaleMerkle, node),
            "Invalid proof."
        );
        _mintLoop(account, mintAmounts);
        presaleClaimed[account] += mintCount;
    }

    function mintFreesale(
        address account,
        uint256[3] memory mintAmounts,
        bytes32[] calldata merkleProof
    ) public mintCompliance(mintAmounts) {
        bytes32 node = keccak256(
            abi.encodePacked(account, maxPerFreesaleAddress)
        );
        uint256 mintCount = (mintAmounts[0] + mintAmounts[1] + mintAmounts[2]);
        require(presale, "No presale minting currently.");
        require(mintCount == 1, "Only 1 free.");
        require(
            freesaleClaimed[account] + mintCount <= maxPerFreesaleAddress,
            "Exceeds max mints for presale."
        );
        require(
            MerkleProof.verify(merkleProof, freesaleMerkle, node),
            "Invalid proof."
        );
        _mintLoop(account, mintAmounts);
        freesaleClaimed[account] += mintCount;
    }

    function mint(uint256[3] memory mintAmounts)
        public
        payable
        mintCompliance(mintAmounts)
    {
        uint256 mintCount = (mintAmounts[0] + mintAmounts[1] + mintAmounts[2]);
        require(!presale, "Only presale minting currently.");
        require(msg.value >= cost * mintCount, "Insufficient funds.");
        _mintLoop(msg.sender, mintAmounts);
    }

    function mintForAddress(uint256[3] memory mintAmounts, address _receiver)
        public
        mintCompliance(mintAmounts)
        onlyOwner
    {
        uint256 mintCount = (mintAmounts[0] + mintAmounts[1] + mintAmounts[2]);
        require(
            reserveCount + mintCount <= reserveLimit,
            "Exceeds max of 888 reserved."
        );
        _mintLoop(_receiver, mintAmounts);
        reserveCount += mintCount;
    }

    function _mintLoop(address _receiver, uint256[3] memory mintAmounts)
        internal
    {
        for (uint256 i = 0; i < mintAmounts[0]; i++) {
            supply.increment();
            newtonSupply.increment();
            tokenIdsToBase[supply.current()] = 0;
            _safeMint(_receiver, supply.current());
        }
        for (uint256 i = 0; i < mintAmounts[1]; i++) {
            supply.increment();
            davisSupply.increment();
            tokenIdsToBase[supply.current()] = 1;
            _safeMint(_receiver, supply.current());
        }
        for (uint256 i = 0; i < mintAmounts[2]; i++) {
            supply.increment();
            hamptonSupply.increment();
            tokenIdsToBase[supply.current()] = 2;
            _safeMint(_receiver, supply.current());
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );
        if (revealed == false) {
            string memory baseId;
            string memory currentHiddenURI = uriHidden;
            if (tokenIdsToBase[_tokenId] == 0) {
                baseId = "newton";
            } else if (tokenIdsToBase[_tokenId] == 1) {
                baseId = "davis";
            } else {
                baseId = "hampton";
            }
            return
                bytes(currentHiddenURI).length > 0
                    ? string(
                        abi.encodePacked(currentHiddenURI, baseId, uriSuffix)
                    )
                    : "INVALID";
        }
        string memory currentBaseURI = uriPrefix;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "INVALID";
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function newtonTotalSupply() public view returns (uint256) {
        return newtonSupply.current();
    }

    function davisTotalSupply() public view returns (uint256) {
        return davisSupply.current();
    }

    function hamptonTotalSupply() public view returns (uint256) {
        return hamptonSupply.current();
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function setPresaleMerkle(bytes32 newRoot) public onlyOwner {
        presaleMerkle = newRoot;
    }
    function setFreesaleMerkle(bytes32 newRoot) public onlyOwner {
        freesaleMerkle = newRoot;
    }

    function setUriPrefix(string memory newUriPrefix) public onlyOwner {
        uriPrefix = newUriPrefix;
    }

    function setUriSuffix(string memory newUriSuffix) public onlyOwner {
        uriSuffix = newUriSuffix;
    }

    function setUriHidden(string memory newUriHidden) public onlyOwner {
        uriHidden = newUriHidden;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxPerPresaleAddress(uint256 _maxPerPresaleAddress)
        public
        onlyOwner
    {
        maxPerPresaleAddress = _maxPerPresaleAddress;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(devAddress, ((balance * 15) / 100));
        _widthdraw(dev2Address, ((balance * 5) / 100));
        _widthdraw(artistAddress, ((balance * 5) / 100));
        _widthdraw(eventsAddress, ((balance * 5) / 100));
        _widthdraw(investorAddress, ((balance * 5) / 100));
        _widthdraw(contributersAddress, ((balance * 15) / 100));
        _widthdraw(communityAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }
}

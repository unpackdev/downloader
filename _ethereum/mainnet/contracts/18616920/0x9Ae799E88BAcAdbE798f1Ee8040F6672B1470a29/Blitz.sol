pragma solidity 0.8.22;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProofLib.sol";
import "./ECDSA.sol";
import "./Address.sol";
import "./LibString.sol";

interface BEG {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Blitz is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Address for address;

    address public immutable begToken;
    address private signerAddress;

    bytes32 public begRoot;
    bytes32 public whitelistRoot;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price = 0.08 ether;

    uint256 public whitelistOpen;
    uint256 public whitelistClosed;

    uint256 public emissionTime;
    uint256 public begPerBlitz;

    bool public live;

    string private _baseURIString;

    struct Staker {
        uint256 lastClaim;
        uint256[] tokenIds;
    }

    mapping(address => bool) public begClaimed;
    mapping(address => Staker) public stakers;
    mapping(uint256 => bool) public stakedTokens;
    mapping(address => uint256) public nonces;

    event Staked(address indexed user, uint256[] tokenIds, uint256 stakeTime);
    event Unstaked(address indexed user, uint256[] tokenIds);
    event Claimed(address indexed user, uint256 amount);

    error MintNotLive();
    error WhitelistNotLive();
    error PublicMintNotLive();
    error BegMintClaimed();
    error BegMintUnauthorized();
    error WhitelistMintUnauthorized();
    error SupplyExceeded();
    error InsufficientPayment();
    error InvalidWhitelistWindow();
    error TokenDoesNotExist();
    error NoTokens();
    error NotOwner();
    error AlreadyStaked();
    error InsufficientBeg();
    error NotStaked();
    error InvalidNonce();
    error InvalidSignature();

    modifier whitelistMintActive() {
        if (block.timestamp < whitelistOpen) revert WhitelistNotLive();
        if (block.timestamp > whitelistClosed) revert WhitelistNotLive();
        _;
    }

    constructor(bytes32 _begRoot, bytes32 _whitelistRoot, address _begToken, address _signerAddress)
        ERC721A("Blitz", "BLITZ")
    {
        _initializeOwner(msg.sender);
        begToken = _begToken;
        begRoot = _begRoot;
        whitelistRoot = _whitelistRoot;
        signerAddress = _signerAddress;
        emissionTime = 24 hours;
    }

    function begMint(bytes32[] calldata proof) external whitelistMintActive {
        if (!live) revert MintNotLive();
        if (begClaimed[msg.sender]) revert BegMintClaimed();
        if (!MerkleProofLib.verify(proof, begRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert BegMintUnauthorized();
        }

        begClaimed[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function whitelistMint(bytes32[] calldata proof, uint256 _amount) external payable whitelistMintActive {
        if (!live) revert MintNotLive();
        if (totalSupply() + _amount > MAX_SUPPLY) revert SupplyExceeded();
        if (!MerkleProofLib.verify(proof, whitelistRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert WhitelistMintUnauthorized();
        }
        if (msg.value != _amount * price) revert InsufficientPayment();

        _mint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external payable {
        if (!live) revert MintNotLive();
        if (block.timestamp < whitelistClosed) revert PublicMintNotLive();
        if (totalSupply() + _amount > MAX_SUPPLY) revert SupplyExceeded();
        if (msg.value != _amount * price) revert InsufficientPayment();

        _mint(msg.sender, _amount);
    }

    function stake(uint256[] calldata _tokenIds) external {
        if (_tokenIds.length == 0) revert NoTokens();

        for (uint256 i; i < _tokenIds.length; i++) {
            if (!_exists(_tokenIds[i])) revert TokenDoesNotExist();
            if (ownerOf(_tokenIds[i]) != msg.sender) revert NotOwner();
            if (stakedTokens[_tokenIds[i]]) revert AlreadyStaked();

            stakers[msg.sender].tokenIds.push(_tokenIds[i]);
            stakedTokens[_tokenIds[i]] = true;
        }

        stakers[msg.sender].lastClaim = block.timestamp;
        emit Staked(msg.sender, _tokenIds, block.timestamp);
    }

    function claim() public {
        uint256 reward = calculateReward(msg.sender);

        if (reward == 0) return; // noop
        if (reward > BEG(begToken).balanceOf(address(this))) revert InsufficientBeg();

        stakers[msg.sender].lastClaim = block.timestamp;
        BEG(begToken).transfer(msg.sender, reward);
        emit Claimed(msg.sender, reward);
    }

    function calculateReward(address addr) public view returns (uint256) {
        Staker storage staker = stakers[addr];
        uint256 timeSinceClaim = block.timestamp - staker.lastClaim;
        if (staker.tokenIds.length == 0 || timeSinceClaim < emissionTime) return 0;
        return (timeSinceClaim / emissionTime) * begPerBlitz * staker.tokenIds.length;
    }

    function claimEngagement(uint256 _amount, uint256 _nonce, bytes memory _signature) public {
        if (nonces[msg.sender] != _nonce) revert InvalidNonce();
        if (!isValidSignature(msg.sender, _amount, _nonce, _signature)) revert InvalidSignature();

        unchecked {
            nonces[msg.sender]++;
        }

        BEG(begToken).transfer(msg.sender, _amount);

        emit Claimed(msg.sender, _amount);
    }

    function unstake(uint256[] calldata _tokenIds) external {
        if (_tokenIds.length == 0) revert NoTokens();
        claim();

        Staker storage staker = stakers[msg.sender];

        for (uint256 j; j < _tokenIds.length; j++) {
            bool found = false;
            for (uint256 i; i < staker.tokenIds.length; i++) {
                if (staker.tokenIds[i] == _tokenIds[j]) {
                    if (!stakedTokens[_tokenIds[j]]) revert NotStaked();

                    staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length - 1];
                    staker.tokenIds.pop();
                    delete stakedTokens[_tokenIds[j]];

                    found = true;
                    break;
                }
            }
            if (!found) revert NotStaked();
        }
        emit Unstaked(msg.sender, _tokenIds);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setLive() external onlyOwner {
        live = !live;
    }

    function setWhitelistMintWindow(uint256 _whitelistOpen, uint256 _whitelistClosed) external onlyOwner {
        if (_whitelistOpen > _whitelistClosed) revert InvalidWhitelistWindow();
        if (_whitelistOpen == 0) revert InvalidWhitelistWindow();
        if (_whitelistClosed == 0) revert InvalidWhitelistWindow();

        whitelistOpen = _whitelistOpen;
        whitelistClosed = _whitelistClosed;
    }

    function setBegRoot(bytes32 _begRoot) external onlyOwner {
        begRoot = _begRoot;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setBegPerBlitz(uint256 _begPerBlitz) external onlyOwner {
        begPerBlitz = _begPerBlitz;
    }

    function setTokenURI(string calldata uri) external onlyOwner {
        _baseURIString = uri;
    }

    function setEmissionTime(uint256 _hours) external onlyOwner {
        emissionTime = _hours * 1 hours;
    }

    function setSigner(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI = _baseURIString;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, LibString.toString(tokenId))) : "";
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function rescueBeg() external onlyOwner {
        BEG(begToken).transfer(msg.sender, BEG(begToken).balanceOf(address(this)));
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        if (stakedTokens[startTokenId]) revert AlreadyStaked();
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function getStaker(address stakerAddress) external view returns (Staker memory) {
        return stakers[stakerAddress];
    }

    function getTokenStatuses(uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory statuses = new bool[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            statuses[i] = stakedTokens[tokenIds[i]];
        }
        return statuses;
    }

    function isValidSignature(address _user, uint256 _amount, uint256 _nonce, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(_user, _amount, _nonce, address(this)));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recoveredSigner = ECDSA.recover(prefixedHash, _signature);

        return recoveredSigner == signerAddress;
    }
}

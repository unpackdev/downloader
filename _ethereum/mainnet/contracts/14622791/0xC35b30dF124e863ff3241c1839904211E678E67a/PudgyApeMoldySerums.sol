pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./FridgeInterface.sol";

contract PudgyApeMoldySerums is ERC1155, Pausable, Ownable, ReentrancyGuard, PaymentSplitter {
    using ECDSA for bytes32;

    uint256[] private _shares = [10,20,70];
    address[] private _shareholders = [
        0x81Bf2Bc8119695ed2A196556e4182DaF49872163,
        0x3461895e441a1D368E04525276B96Aeb87431fe9,
        0x3584fE4F1e719FD0cC0F814a4A675181438B45DD
    ];

    //Start timestamp
    uint public startTime = 1650474000;

    //Serum types
    uint public immutable M1Serum = 1;
    uint public immutable M2Serum = 2;
    uint public immutable M3Serum = 3;
    mapping(uint => bool) public validSerumTypes;

    //Claims
    mapping(uint => bool) public pudgyApesUsed;

    //Metadata
    string public name = "Pudgy Ape Moldy Serums";
    string public symbol = "PAMS";
    string public baseURI;

    //Contracts
    address public SNAC;
    address public PudgyApes;
    address public MutantPudgies;
    address public Fridge;

    //Signer
    address private signer;

    uint public snackPrice = 1200 ether;
    uint public ethPrice = 0.015 ether;

    constructor(address _pudgyApes, address _snac, address _fridge , string memory _uri)
        ERC1155(
            _uri
        )
        PaymentSplitter(_shareholders, _shares)
        {
            baseURI = _uri;
            validSerumTypes[M1Serum] = true;
            validSerumTypes[M2Serum] = true;
            validSerumTypes[M3Serum] = true;
            Fridge = _fridge;
            PudgyApes = _pudgyApes;
            SNAC = _snac;
        }

    //CLAIM
    function claimForSnack(uint[] calldata _ids, bytes[] memory signature) external whenNotPaused nonReentrant {
        require(isClaimingOpen(), "PudgySerums: Claiming is not open yet!");
        require(IERC20(SNAC).balanceOf(msg.sender) >= snackPrice*_ids.length, "PudgySerums: You don't have enough SNAC to claim!");
        IERC20(SNAC).transferFrom(msg.sender,address(Fridge), snackPrice*_ids.length);
        for(uint i = 0; i < _ids.length; i++) {
            uint serumType = getTypeFromSignature(_ids[i], signature[i]);
            require(serumType != 0, "PudgySerums: Invalid signature!");
            require(ownedOrStaked(_ids[i]), "PudgySerums: You don't own this token!");
            require(!isClaimed(_ids[i]), "PudgySerums: The allocated serum has already been claimed!");
            pudgyApesUsed[_ids[i]] = true;
            _mint(msg.sender, serumType, 1, "");
        }
    }

    function claimForETH(uint[] calldata _ids, bytes[] memory signature) external payable whenNotPaused nonReentrant {
        require(isClaimingOpen(), "PudgySerums: Claiming is not open yet!");
        require(msg.value >= ethPrice*_ids.length, "PudgySerums: Not enough ETH!");
        for(uint i = 0; i < _ids.length; i++) {
            uint serumType = getTypeFromSignature(_ids[i], signature[i]);
            require(serumType != 0, "PudgySerums: Invalid signature!");
            require(ownedOrStaked(_ids[i]), "PudgySerums: You don't own this token!");
            require(!isClaimed(_ids[i]), "PudgySerums: The allocated serum has already been claimed!");
            pudgyApesUsed[_ids[i]] = true;
            _mint(msg.sender, serumType, 1, "");
        }
    }

    function getTypeFromSignature(uint id, bytes memory signature) internal view returns (uint) {
        for(uint i = 1; i <= 3; i++) {
            bytes32 hash = keccak256(abi.encodePacked(id, i));
            bytes32 messageHash = hash.toEthSignedMessageHash();
            if(messageHash.recover(signature) == signer) {
                return i;
            }
        }
        return 0;
    }

    //BURN
    function consumeSerum(uint _serumType, address _account) external whenNotPaused {
        require(msg.sender == MutantPudgies, "PudgySerums: Only burner contract can consume serums!");
        require(validSerumTypes[_serumType], "PudgySerums: Invalid serum type!");
        _burn(_account, _serumType, 1);
    }

    function isClaimingOpen() public view returns (bool) {
        return block.timestamp >= startTime;
    }

    function isClaimed(uint _tokenId) public view returns (bool) {
        return pudgyApesUsed[_tokenId];
    }

    function ownedOrStaked(uint _tokenId) public view returns (bool) {
        uint[] memory stakedTokens = FridgeInterface(Fridge).tokensStaked(msg.sender);
        bool isStaked = false;
        for(uint i = 0; i < stakedTokens.length; i++) {
            if(stakedTokens[i] == _tokenId) {
                isStaked = true;
            }
        }
        return IERC721(PudgyApes).ownerOf(_tokenId) == msg.sender || isStaked;
    }

    //Pause
    function pause() external onlyOwner {
        _pause();
    }

    //Unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    //Metadata URI
    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(validSerumTypes[_tokenId], "PudgySerums: Invalid serum type!");
        return string(abi.encodePacked(abi.encodePacked(baseURI, Strings.toString(_tokenId)), ".json"));
    }

    //Set PudgyApes
    function setPudgyApes(address _pudgyApes) external onlyOwner {
        PudgyApes = _pudgyApes;
    }

    //Set Mutant Pudgies
    function setMutantPudgies(address _mutantPudgies) external onlyOwner {
        MutantPudgies = _mutantPudgies;
    }

    //Set SNAC
    function setSnac(address _snac) external onlyOwner {
        SNAC = _snac;
    }

    //Set Fridge
    function setFridge(address _fridge) external onlyOwner {
        Fridge = _fridge;
    }

    //Set start time
    function setStartTime(uint _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setSnackPrice(uint _price) external onlyOwner {
        snackPrice = _price;
    }

    function sethETHPrice(uint _price) external onlyOwner {
        ethPrice = _price;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }
}
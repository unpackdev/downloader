// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./IStandardERC20.sol";
import "./IPixelNFT.sol";
import "./IVRF2.sol";

contract PixelNFTMinter is AccessControl {
    using ECDSA for bytes32;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    enum Status {
        PreSale,
        Public,
        Completed,
        WinnerSelected,
        Converted,
        Canceled
    }
    Status public status;
    uint256 public unitPrice;
    uint8 public maxPerUser;
    mapping(address => uint256) public userMinted;
    uint256 public maxCap;
    bool public paused;
    uint256 private requestId;
    uint256 public winnerID;
    address public winnerAddress;
    uint8 public adminFeePercent;
    uint256 public publicStartTime;
    uint256 public preSaleStartTime;
    mapping(address => uint256) public userBalance;

    bytes32 public merkleRoot;
    address public owner;
    IPixelNFT public nftContract;
    IVRF2 public vrf;

    event WinnerSelected(uint256 _requestId, uint256 _randomWord, uint256 _winnerID, address _winnerAddress);
    event PriceUpdated(uint256 _price);
    event PublicTimeUpdated(uint256 _time);
    event PreSaleTimeUpdated(uint256 _time);
    event PauseUpdated(bool _enabled);
    event MaxPerUserUpdated(uint8 _maxPerUser);
    event FeePercentUpdated(uint8 _feePercent);
    event StatusUpdated(Status status);

    constructor(
        address _owner,
        address nftContractAddress,
        address _vrfAddress,
        uint256 _unitPrice,
        uint8 _maxPerUser,
        uint8 _adminFeePercent,
        uint256 _preSaleStartTime,
        uint256 _publicSaleStartTime
    ){
        nftContract = IPixelNFT(nftContractAddress);
        vrf = IVRF2(_vrfAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(ADMIN_ROLE, _owner);
        owner = _owner;
        unitPrice = _unitPrice;
        maxPerUser = _maxPerUser;
        adminFeePercent = _adminFeePercent;
        status = Status.PreSale;
        preSaleStartTime = _preSaleStartTime;
        publicStartTime = _publicSaleStartTime;
        emit StatusUpdated(status);
    }

    modifier isMintValid(uint256 _count, address _to) {
        require(_count + userMinted[_to] <= maxPerUser, "!maxPerUser");
        require(msg.value == price(_count), "!value");
        _;
    }

    function mint(
        address _to,
        uint _count,
        bytes32[] calldata _proof
    ) public payable isMintValid(_count, _to) {
        require(!paused, 'paused');
        require(status == Status.PreSale || status == Status.Public, 'unavailable');
        if (status == Status.PreSale) {
            require(preSaleStartTime <= block.timestamp, 'preSale is not started');
            require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_to))), "!proof");
        }
        if (status == Status.Public) {
            require(publicStartTime <= block.timestamp, 'public mint is not started');
        }
        _mint(_to, _count);
        userBalance[_to] += msg.value;
        userMinted[_to] += _count;
        if (nftContract.getMaxSupply() == nftContract.totalSupply()) {
            status = Status.Completed;
            emit StatusUpdated(status);
            selectWinner();
        }
    }

    function _mint(address _to, uint _count) private {
        for(uint i = 0; i < _count; i++){
            nftContract.mint(_to, nftContract.totalSupply() + 1);
        }
    }

    function selectWinner() private {
        requestId = vrf.requestRandomWords();
    }

    function adminSelectWinner() public onlyRole(ADMIN_ROLE) {
        return selectWinner();
    }

    function awardToWinner(uint256 _requestId, uint256 _randomWord) public returns(bool) {
        require(msg.sender == address(vrf), 'Only VRF');
        require(requestId == _requestId, '!requestID');
        winnerID = (_randomWord % nftContract.totalSupply()) + 1;
        winnerAddress = nftContract.ownerOf(winnerID);
        require(award(winnerAddress), '!award');
        status = Status.WinnerSelected;
        emit StatusUpdated(status);
        emit WinnerSelected(_requestId, _randomWord, winnerID, winnerAddress);
        return true;
    }

    function award(address _winner) private returns(bool) {
        uint256 balance = address(this).balance;
        uint256 fee = balance * adminFeePercent / 100;
        uint256 winningShare = balance - fee;
        payable(_winner).transfer(winningShare);
        payable(owner).transfer(fee);
        return true;
    }

    function price(uint _count) public view returns (uint256) {
        return _count * unitPrice;
    }

    function refund() public {
        require(status == Status.Canceled, "not canceled");
        require(userBalance[msg.sender] > 0, "!balance");
        payable(msg.sender).transfer(userBalance[msg.sender]);
        userBalance[msg.sender] = 0;
    }

    function updateOwner(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        owner = newOwner;
    }

    function updateUnitPrice(uint256 _unitPrice) public onlyRole(ADMIN_ROLE) {
        unitPrice = _unitPrice;
        emit PriceUpdated(_unitPrice);
    }

    function updateStatus(Status _status) public onlyRole(ADMIN_ROLE) {
        status = _status;
        emit StatusUpdated(_status);
    }

    function updatePaused(bool _pause) public onlyRole(ADMIN_ROLE) {
        paused = _pause;
        emit PauseUpdated(_pause);
    }

    function updateMaxPerUser(uint8 _maxPerUser) public onlyRole(ADMIN_ROLE) {
        maxPerUser = _maxPerUser;
        emit MaxPerUserUpdated(_maxPerUser);
    }

    function updateFeePercent(uint8 _fee) public onlyRole(ADMIN_ROLE) {
        adminFeePercent = _fee;
        emit FeePercentUpdated(_fee);
    }

    function updateNftContrcat(IPixelNFT _newAddress) public onlyRole(ADMIN_ROLE) {
        nftContract = IPixelNFT(_newAddress);
    }

    function updateVRF(IVRF2 _newAddress) public onlyRole(ADMIN_ROLE) {
        vrf = IVRF2(_newAddress);
    }

    function updatePublicStartTime(uint256 _time) public onlyRole(ADMIN_ROLE) {
        publicStartTime = _time;
        emit PublicTimeUpdated(_time);
    }

    function updatePreSaleStartTime(uint256 _time) public onlyRole(ADMIN_ROLE) {
        preSaleStartTime = _time;
        emit PreSaleTimeUpdated(_time);
    }

    function setMerkleRoot(bytes32 _root) external onlyRole(ADMIN_ROLE) {
        merkleRoot = _root;
    }

    function ownerWithdrawTokens(uint256 amount, address _to, address _tokenAddr) public onlyRole(ADMIN_ROLE) {
        require(_to != address(0));
        if(_tokenAddr == address(0)){
            payable(_to).transfer(amount);
        } else {
            IStandardERC20(_tokenAddr).transfer(_to, amount);
        }
    }
}

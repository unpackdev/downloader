// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.12.6 https://hardhat.org

import "./AccessControl.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./Address.sol";

pragma solidity ^0.8.0;


contract ApNftVesting is  Pausable, AccessControl
{
    using Address for address;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");


    struct ApNFT {
        uint256 batchNo;
        address from;
        address token;
        uint256 tokenId;
        uint256 serialNo;
    }


    // apNFT received address
    address private apNFTReceivedAddress;


    // user=> { apNft => tokenIDs }
    mapping(address => mapping(address => uint256[])) private userTransferRecords;
    // apNft => tokenID => address
    mapping(address => mapping(uint256 => address) ) private apNftRecords;
    // batchNo => searilNo 
    mapping(uint256=> uint256[]) private batchNoMap;
    // searilNo => ApNFT 
    mapping(uint256=> ApNFT) private searilNoMap;


    // Event Transfer
    event ApNftTransfer(address indexed apNFTaddess, address indexed from, uint256 indexed tokenID, uint256 time, uint256 serialNo, uint256 batchNo);

    modifier onlyNFT(address token) {
        require(token.isContract(), "Only CA");
        _;
    }

    constructor(
        address admin,
        address receivedAddress
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
        apNFTReceivedAddress = receivedAddress;

    }

    receive() external payable {}

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /**
     * Batch transfer
     */
    function batchTransfer(uint256 _batchNo, address _apNFTaddess, uint256[] calldata _tokenIDs, uint256[] calldata _serialNos) external whenNotPaused() onlyNFT(_apNFTaddess) {
        require(_tokenIDs.length > 0, "tokenIDs size can not be zero");
        require(_serialNos.length == _tokenIDs.length, "The length of array [_tokenIDs] and array [_serialNos] does not match");
        for(uint256 i=0; i< _tokenIDs.length; i++){
            transfer(_batchNo, _apNFTaddess, _tokenIDs[i], _serialNos[i]);
        }
    }

    function transfer(uint256 _batchNo,address _apNFTaddess, uint256 _tokenID,uint256 _serialNo) public whenNotPaused() onlyNFT(_apNFTaddess) {
        require(_tokenID > 0, "tokenID can not be zero");
        require(apNFTReceivedAddress !=address(0), "received address is null");
        IERC721(_apNFTaddess).transferFrom(msg.sender, apNFTReceivedAddress, _tokenID);
        emitApNftTransfer(_batchNo,_apNFTaddess, _tokenID, _serialNo);
    }

    function emitApNftTransfer(
        uint256 _batchNo,
        address _apNFTaddess,
        uint256 _tokenID,
        uint256 _serilNo) internal {
        
        // user transfer
        userTransferRecords[msg.sender][_apNFTaddess].push(_tokenID);
        apNftRecords[_apNFTaddess][_tokenID]=msg.sender;
        // mapping(uint256=> uint256[]) private batchNoMap;
        batchNoMap[_batchNo].push(_serilNo);
        //mapping(uint256=> ApNFTDrop) private searilNoMap;
        searilNoMap[_serilNo] = ApNFT(_batchNo,msg.sender, _apNFTaddess,_tokenID,_serilNo);

        // ApNftTransfer(address indexed apNFTaddess, address indexed from, uint256 indexed tokenID, uint256 time, uint256 serialNo, uint256 batchNo)
        emit ApNftTransfer(_apNFTaddess, msg.sender, _tokenID, block.timestamp, _serilNo, _batchNo);

    }

    /**
     *  set received address
     */
    function setReceivedAddress(address _receivedAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        apNFTReceivedAddress = _receivedAddress;
    }


    /**
     *  get received address
     */
    function getReceivedAddress() external view returns (address){
       return apNFTReceivedAddress;
    }

    
    /**
     *  get Transfer Record
     */
    function getTransferRecords(address owner, address apNFTaddess) external view  returns (uint256[] memory tokenIDs){
        tokenIDs = userTransferRecords[owner][apNFTaddess];
       return tokenIDs;
    }

        /**
     *  get Transfer Record
     */
    function getApNftRecords(address apNFTaddess, uint256 tokenID) external view  returns (address user){
        user = apNftRecords[apNFTaddess][tokenID];
       return user;
    }

    function getApNFT(uint256 _serilNo)
        external
        view
        returns (uint256, address, address, uint256, uint256)
    {
        ApNFT storage nft = searilNoMap[_serilNo];
        return (nft.batchNo, nft.from, nft.token, nft.tokenId, nft.serialNo);
    }

    function getBatchSerilNo(uint256 _batchNo)
        external
        view
        returns (uint256[] memory)
    {
        return batchNoMap[_batchNo];
    }


}

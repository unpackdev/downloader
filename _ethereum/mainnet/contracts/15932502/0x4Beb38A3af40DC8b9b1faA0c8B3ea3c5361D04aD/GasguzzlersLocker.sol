//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./NonblockingLzApp.sol";
import "./console.sol";
contract GasguzzlerLocker is OwnableUpgradeable, NonblockingLzApp {

    IERC721Upgradeable public gasguzzler;
    uint256 gas;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    function init(address _nftAddress, address endpointAddress) external initializer {
        __Ownable_init();
        __nonblockingLzApp_init(endpointAddress);
        gasguzzler = IERC721Upgradeable(_nftAddress);
        gas = 300000;
    }

    function lockAndMigrateTokens(uint[] memory tokenIds, bytes memory _migrateTo, uint16 destinationChainId) external payable {
        for (uint i=0; i<tokenIds.length; i++) {
            gasguzzler.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        uint16 version = 1;
        uint256 _gas = gas * tokenIds.length;
        bytes memory adapterParameters = abi.encodePacked(version, _gas);
        bytes memory payload = abi.encode(_migrateTo, tokenIds);
        (uint256 messageFees,) = lzEndpoint.estimateFees(destinationChainId, address(this), payload, false, adapterParameters);
        require (msg.value >= messageFees, "Error: Insufficient Fees");
        _lzSend(destinationChainId, payload, payable(msg.sender), address(0), adapterParameters);
    }

    function disburseTokens (address _toSend, uint256[] memory tokenIds) internal {
        for (uint i=0; i<tokenIds.length; i++) {
            gasguzzler.safeTransferFrom(address(this), _toSend, tokenIds[i]);
        }
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        (bytes memory toAddressBytes, uint256[] memory tokenIds) = abi.decode(
            _payload,
            (bytes,uint256[])
        );

        address _toAddress;
        assembly {
            _toAddress := mload(add(toAddressBytes,20))
        }
        disburseTokens(_toAddress, tokenIds);
    }

    function rescue (address[] memory _userAddresses, uint256[] memory _tokenIds) public onlyOwner {
        require (_userAddresses.length == _tokenIds.length, "Error: Length Mismatch");
        uint256 _len = _userAddresses.length;
        for(uint i=0;i<_len;i++) {
            gasguzzler.safeTransferFrom(address(this), _userAddresses[i], _tokenIds[i]);
        }
    }

    function setNFTAddress(address _nftAddress) public onlyOwner {
        gasguzzler = IERC721Upgradeable(_nftAddress);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        address userAddress,
        uint16 destinationChainId,
        uint[] memory tokenIds
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        return
        lzEndpoint.estimateFees(
            destinationChainId,
            address(this),
            abi.encode(userAddress, tokenIds),
            false,
            abi.encodePacked(uint16(1),uint256(gas*tokenIds.length))
        );
    }

    //@dev Receive the tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return _ERC721_RECEIVED;
    }

}

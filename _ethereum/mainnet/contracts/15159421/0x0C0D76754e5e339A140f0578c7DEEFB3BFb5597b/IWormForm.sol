// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWormForm {
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _secondBaseURI,
        string memory _ticketURI,
        string memory _cocoonURI,
        address _oldNFTContract,
        address _backendAddress,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint32[] memory _stakingTime,
        uint32[] memory _claimables,
        uint32[] memory _uint256Arr
    ) external;
    function mintTo(address _to, uint256 _id) external;
    function mintToAddresses(address[] memory _addresses, uint256[] memory _ids) external;
    function changePrice(uint256 _newPrice) external;
    function switchRevealed() external;
    function switchTicketSale() external;
    function setExtension(string memory _ext) external;
    function setBackendAddress(address _newBackendAddress) external;
    function checkStamina(uint256 _tokenId) external view returns(uint256);
    function purchaseTicket(uint256 _amount) external payable;
    function giftTicket(address _to, uint256 _amount) external;
    function switchStaking() external;
    function setBaseTokenURI(string memory _uri) external;
    function revealMetadataURI(string memory _uri) external;
    function tokenURI(uint256 tokenId) external view returns(string memory);
    function getCocoonURI() external view returns(string memory);
    function setCocoonURI(string memory _cocoonURI) external;
    function stakeToBreed(uint256 _ATokenId, uint256 _BTokenId) external;
    function unstakeFromBreeding() external;
    function hatchCocoon(uint256 _tokenId, string memory _uri, bytes32 _hash, bytes memory _signature) external;
    function getUserStakeInfo(address _user) external view returns(bool _isStaked, uint256 _tokenA, uint256 _tokenB, uint256 _stakedAt);
    function withdraw() external payable;
    function pause() external;
    function changeOldNFTContract(address _new) external;
    function unpause() external;
    function ticketsLeft() external view  returns(uint256);
}
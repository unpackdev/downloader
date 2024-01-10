// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRPFStoryPaper {

    event mintEvent(address owner, uint256 quantity, uint256 totalSupply);

    event phaseOneWritten(uint256 tokenId, uint256 rpfTokenId, string name, string story);

    function verify(uint256 maxQuantity, bytes memory SIGNATURE) external view returns(bool);

    function mintGiveawayPaper(address _to, uint256 quantity) external;

    function claimRPFPaper(uint256 quantity, uint256 maxClaimNum, bytes memory SIGNATURE) external;

    function writePaperPhase1(uint256 tokenId, uint256 rpfTokenId, string memory name, string memory story) external;

    function getRPFName(uint256 tokenId) external view returns(string memory);

    function getStory(uint256 tokenId) external view returns(string memory);

    function getPaperStatus(address owner) external view returns(bool[] memory);

    function tokensOfOwner(address _owner) external view returns(uint256[] memory );

    function setRPFAddress(address _RPF) external;

    function setWritePhase(bool _hasPhaseOneStarted, uint256 _phaseOneTimestamp) external;

    function setClaim(bool _hasClaimStarted, uint256 _claimTimestamp) external;

    function setURI(string calldata _tokenURI) external;

    function setTreasury(address _treasury) external;

    function withdrawAll() external payable;
}
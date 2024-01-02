// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBackerNFT {
    /* ============ Events =============== */
    event ChangedBaseURI(string _tokenBaseURI);
    event TokenCreated(address indexed _receiver, uint256 tokenId, uint256 timestamp);
    /* ============ Functions ============ */
    // mint
    function mint(address account) external;
    function mintBatch(address _account, uint256 _amount) external;
    function burn(uint256 id) external;
    function burnBatch(uint256[] calldata ids) external;
    function updateMinter(address _minter, bool _persmission) external;
}
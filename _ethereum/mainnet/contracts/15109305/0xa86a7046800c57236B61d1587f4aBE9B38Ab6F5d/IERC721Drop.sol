// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Drop {
    /*
    * @title whitelistMint
    * @notice ホワイトリスト用のmint関数
    * @param トークンID
    * @param マークルプルーフ
    * @dev マークルツリーを利用
    * @dev フリーミント時に対応
    */
    function whitelistMint(bytes32[] calldata _merkleProof) external;

    /*
    * @title mintByOwner
    * @notice バルクミント用
    * @param 送信先
    * @dev 
    */
    function mintByOwner(address[] calldata _to) external;

    /*
    * @title addMerkleRoot
    * @notice マークルルートの設定
    * @dev ホワイトリスト用
    */
    function setMerkleRoot(bytes32 _merkleRoot) external;

    /*
    * @title readySales
    * @notice プレセールの開始
    * @dev 列挙型で管理
    */
    function readySales() external;

    /*
    * @title startFreeMint
    * @notice フリーミントの開始
    * @dev 列挙型で管理
    */
    function startFreeMint() external;

    /*
    * @title suspendSale
    * @notice フリーミントの停止
    * @dev 列挙型で管理
    */
    function suspendSale() external;

    /*
    * @title license
    * @notice エージェントの設定
    * @param エージェントのアドレス
    * @dev 
    */
    function license(address _agentAddr) external;

    /*
    * @title unlicense
    * @notice エージェントの削除
    * @param エージェントのアドレス
    * @dev 
    */
    function unlicense(address _agentAddr) external;

    /*
    * @title inventoryReplenishment
    * @dev 
    */
    function inventoryReplenishment(uint256 _amount) external;

    /*
    * @title setBaseURI
    * @dev 
    */
    function setBaseURI(string memory uri_) external;
}
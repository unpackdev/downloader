// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IERC721Drop.sol";

/* mandatory parameter
*  1. name 
*  2. symbol 
*/ 
// should inherit either RevenuePool or Ownable due to Ownable linearization
contract ERC721Drop is ERC721, IERC721Drop{
  using SafeMath for uint256;

  // トークンの供給量
  uint256 public tokenSupply;
  // マークルルート
  bytes32 public merkleRoot;
  // 供給量の上限
  uint256 public MAX_AMOUNT_OF_MINT;
  // コントラクトの作成者
  address private _creator;
  // ベースURI
  string private baseURI_;

  // 販売状態(列挙型)
  enum SaleState {PreRelease, FreeMint, Suspended} 
  SaleState sales;

  // 実行権限のある執行者
  mapping(address => bool) private _agent;
  // ホワイトリストの既請求者
  mapping(address => bool) public whitelistClaimed;

  event NowOnSale(SaleState sales);
  event Stock(uint256 _amount);

  constructor (
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol){
    MAX_AMOUNT_OF_MINT = 48;
    _creator = msg.sender;
    readySales();
  }

  /*
  * @title onlyCreatorOrAgent
  * @notice 実行権限の確認
  * @div 
  */
  modifier onlyCreatorOrAgent {
    require(msg.sender == _creator || _agent[msg.sender], "This is not allowed except for _creator or agent");
    _;
  }

  /*
  * @title whitelistMint
  * @notice ホワイトリスト用のmint関数
  * @param トークンID
  * @param マークルプルーフ
  * @dev マークルツリーを利用
  * @dev フリーミント時に対応
  */
  function whitelistMint(
    bytes32[] calldata _merkleProof
  ) public virtual override {
    require(sales == SaleState.FreeMint, "NFTs are not now on sale");
    require(!whitelistClaimed[msg.sender], "Address already claimed");
    require(tokenSupply < MAX_AMOUNT_OF_MINT, "Max supply reached");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      "Invalid Merkle Proof."
    );
    whitelistClaimed[msg.sender] = true;

    uint _newTokenId = tokenSupply;
    tokenSupply = tokenSupply.add(1);

    _mint(_msgSender(), _newTokenId);
  }

  /*
  * @title mintByOwner
  * @notice バルクミント用
  * @param 送信先
  * @dev 
  */
  function mintByOwner(
    address[] calldata _to
  )public virtual override onlyCreatorOrAgent {
    require(tokenSupply + _to.length <= MAX_AMOUNT_OF_MINT, "Max supply reached");
    for(uint256 i = 0; i < _to.length; i++){
      uint _newTokenId = tokenSupply;
      tokenSupply = tokenSupply.add(1);

      _mint(_to[i], _newTokenId);
    }
  }

  /*
  * @title addMerkleRoot
  * @notice マークルルートの設定
  * @dev ホワイトリスト用
  */
  function setMerkleRoot(bytes32 _merkleRoot) public virtual override onlyCreatorOrAgent {
    merkleRoot = _merkleRoot;
  }

  /*
  * @title readySales
  * @notice プレセールの開始
  * @dev 列挙型で管理
  */
  function readySales() public virtual override onlyCreatorOrAgent {
    sales = SaleState.PreRelease;
    emit NowOnSale(sales);
  }

  /*
  * @title startFreeMint
  * @notice フリーミントの開始
  * @dev 列挙型で管理
  */
  function startFreeMint() public virtual override onlyCreatorOrAgent {
    sales = SaleState.FreeMint;
    emit NowOnSale(sales);
  }

  /*
  * @title suspendSale
  * @notice フリーミントの停止
  * @dev 列挙型で管理
  */
  function suspendSale() public virtual override onlyCreatorOrAgent {
    sales = SaleState.Suspended;
    emit NowOnSale(sales);
  }

  /*
  * @title license
  * @notice エージェントの設定
  * @param エージェントのアドレス
  * @dev 
  */
  function license(address _agentAddr) public virtual override onlyCreatorOrAgent {
    _agent[_agentAddr] = true;
  }

  /*
  * @title unlicense
  * @notice エージェントの削除
  * @param エージェントのアドレス
  * @dev 
  */
  function unlicense(address _agentAddr) public virtual override onlyCreatorOrAgent {
    _agent[_agentAddr] = false;
  }

  /*
  * @title inventoryReplenishment
  * @dev 
  */
  function inventoryReplenishment(uint256 _amount) public virtual override onlyCreatorOrAgent {
    MAX_AMOUNT_OF_MINT = _amount;
    emit Stock(_amount);
  }

  /*
  * @title setBaseURI
  * @dev 
  */
  function setBaseURI(string memory uri_) public virtual override onlyCreatorOrAgent {
    baseURI_ = uri_;
  }

  /*
  * @title tokenURI
  * @dev 
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI_, Strings.toString(_tokenId)));
  }
}
// SPDX-License-Identifier: LGPL-3.0-or-later 

pragma solidity ^0.8.4;

/**
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@N%i=}9@@@@@@@@@@@@@@@@@@@@@@@Ryl=1H@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@92x13R@@@@@@@@H2x13Q@@@@@K.     \@@@@@@@@@@@@@@@@@@@@@A`     v@@@@@@@@@@@@@@@WHP2yuy%GQ@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@p:     `\N@@@@H^      *R@@@o      `@@@@@@@@@@@@@@@@@@@@Wi      "@@@@@@@@@@@@Ne*_         ,>#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@M-        |@@@N,        \@@@Ni,  `^G@@@@@@@@@@@@@@@@@@@@@N=-  `!K@@@@@@@@@@@G:              :W@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@S          UW@l          R@@@Ne|\sE@@@Nei=i5Nqul(>iuO@@@@@Ru>\xK@@@@@@@@@@@K       !*^,    `s@@@Rel=tU@@@@@H{==uQ@@@H}==1HKui==iu9@@@@@@@@@@g%xl==iC5R@@@@@@Ru==iA@gC=i3M@@@@Rh}=\*r=x3Q@@@@@@@@
 *@@@@@@@@*          :BH           F@@R,     vWR,     '        ~5@@H-     y@@@@@@@@@@u      `\iuA$G5AR@@@R,     vW@@%`    `9@e     `        :xN@@@@Nx~         `!5@@@K-     ;     ~@@K*`          !N@@@@@@
 *@@@@@@@N`           y!           !@@E      :@E                 5@u      !@@@@@@@@@@R-           ."|3N@@E      :@@@*      u@r                ~R@@5'              !R@u            ,@K`     .:-    :R@@@@@@
 *@@@@@@@y      *.          !-      R@E      :@E       xAe,      r@u      !@@@@@@@@@@@Rl_             `u@E      :@@@*      u@r       !i=,      ^WE       zEG*      :Wu        .!=SN@h      ,\voaE#@@@@@@@@
 *@@@@@@@!      3y         `g*      C@E      :@E      :W@@\      \@u      !@@@@@@@@@@@@@N62tr^,`        GE      :@@@*      u@r      y@@@R       N|                  @u      .wN@@@@@@z`         'rO@@@@@@@
 *@@@@@@R       R@"        s@C      ;@E      :@E      :@@@\      \@u      !@@@@@@@@@@@w(*>}3$QNR{       uE      -Q@N~      u@r      lN@@3      `BC       !((((((+\iG@u      \@@@@@@@@Wg2s\;,      `G@@@@@@
 *@@@@@@C      _@@6       ,N@H       RE      :@E      :@@@\      \@u      !@@@@@@@@@@u        ``       _RN`      `:`       E@r       ,^:       s@N"      `"***!:.`,u@u      \@@@@@@@C,  ,!=x^      |@@@@@@
 *@@@@@@(      >@@@v      p@@@_      eO      "@H      ~@@@i      |@2      *@@@@@@@@@@X`              `|R@@U_             `2@@r               .u@@@Nx-              ~Wy      =@@@@@@@"             ~Q@@@@@@
 *@@@@@@Q*`  `\R@@@N\   `C@@@@q!`  _lN@{_   ^E@@C,   ^E@@@R\`  `*R@Ml-  `!g@@@@@@@@@@@Q}*:`      `,*1Q@@@@@Ny*,`      _!xQ@@@r      -`    -!1R@@@@@@NS|"'      .~\yN@Nl-  `\R@@@@@@@N2\:`      _*%N@@@@@@@
 *@@@@@@@@NKHN@@@@@@@QGEN@@@@@@@NOgB@@@@MHOR@@@@@@gOR@@@@@@@NKKN@@@@@NHON@@@@@@@@@@@@@@@@@BRgOOOQN@@@@@@@@@@@@@NHOEOKR@@@@@@@r      uNHOOQB@@@@@@@@@@@@@@RHOOgR@@@@@@@@MgHN@@@@@@@@@@@@@NROOOKR@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@r      u@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@l      5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ni,`.;2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * in collaboration with Purebase Studio https://purebase.co/
 */

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract MiniSupers is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool public paused;
    bool public minting;
    bool public whitelistminting;
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistClaimed;
    uint256 public constant maxBatchSize = 10;
    uint256 public maxPublicPerWallet = 5;
    uint256 public cost = 0.069 ether;
    uint256 public constant maxSupply = 6969;
    uint256 public maxMintAmountPerTx = 5;
    string private _baseTokenURI = 'https://minisupers.io/api/nft/';
    string public provenance;

    constructor() ERC721A("Mini Supers", "MINISUPERS") {
        paused = true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    function flipPause() public onlyOwner {
        paused = !paused;
    }
    function flipMint() public onlyOwner {
        minting = !minting;
    }
    function flipPresaleMint() public onlyOwner {
        whitelistminting = !whitelistminting;
    }
    function setItemPrice(uint256 _price) public onlyOwner {
        cost = _price;
    }
    function setNumPerMint(uint256 _max) public onlyOwner {
        maxMintAmountPerTx = _max;
    }
    function setNumPerWallet(uint256 _max) public onlyOwner {
        maxPublicPerWallet = _max;
    }
    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function mintReserves(uint256 quantity) public onlyOwner {
        require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function presaleMint(uint256 _mintAmount, uint256 _allowance, bytes32[] calldata _merkleProof) public payable callerIsUser {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(!paused, 'The contract is paused!');
        require(whitelistminting, "Whitelist Mint closed");
        require(whitelistClaimed[msg.sender] + _mintAmount <= _allowance, 'More than allowed during WL');
        require(totalSupply() + _mintAmount <= maxSupply, 'More than max supply');
        require(msg.value >= cost * _mintAmount, 'Not enough ETH');
        require(_verify(_leaf(Strings.toString(_allowance), payload), _merkleProof),'Invalid proof');
        
        whitelistClaimed[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable callerIsUser {
        require(!paused, 'The contract is paused!');
        require(minting, "Mint closed");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount');
        require(totalSupply() + _mintAmount <= maxSupply, 'More than max supply');
        require(msg.value >= cost * _mintAmount, 'Not enough ETH');
        require(numberMinted(msg.sender) + _mintAmount <= maxPublicPerWallet + whitelistClaimed[msg.sender], 'More than allowed per wallet');
        
        _safeMint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setProvenance(string memory hash) public onlyOwner {
        provenance = hash;
    }
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
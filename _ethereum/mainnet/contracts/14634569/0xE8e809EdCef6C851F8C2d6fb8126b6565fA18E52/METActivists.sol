// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract METActivists is ERC721A, Ownable {
    bytes32 public rootActivist;
    bytes32 public rootReserve;
    uint256 public immutable ACTIVIST_PRICE = 0.05 ether;
    uint256 public immutable PUBLIC_PRICE = 0.07 ether;
    uint256 public immutable PRESALE_DATE = 1650639600;
    uint256 public immutable PUBLIC_DATE = 1650697200;
    uint256 public immutable END_DATE = 1650718800;
    uint256 public immutable MAX_PER_WALLET = 5;
    uint256 public immutable MAX_PER_TX = 10;
    uint256 public immutable MAX_AMOUNT = 789;
    uint256 public immutable SOFT_CAP = 700;
    address public immutable PROXY_REGISTRY =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint256 public totalClaimed;
    mapping(address => uint256) public reserveClaims;
    mapping(address => uint256) public totalActivistMint;

    // 10000%
    mapping(address => uint256) public contributions;
    bool public teamClaims = false;
    uint256 public revenue;

    string public baseURI_ = "https://takezo.mypinata.cloud/ipfs/QmNNnm91yHdm16bhdkuiTDmsmByWyt2MkFmyCLjvPeT5Uy";
    bool public revealed = false;

    constructor() ERC721A("METActivists", "METActivists") {
        contributions[0xEF5CFFE3878b855513BdC88D84D88e7726ad6908] = 1300;
        contributions[0xCD5D7d2fBeb627452fD44C353DaaA6f06fafA789] = 1300;
        contributions[0x4D8142a1Afd7623998BA0e54238Dda420c68aF07] = 1300;
        contributions[0x71E9E4535d3Df49501A27e67f1Ff2DC0C36644B8] = 1500;
        contributions[0xa17FEf307070bE6e1Ef2de34A2ee110932475aB0] = 550;
        contributions[0x731ec7d7D7578CF3Bd304F7a4c49643DEc31731e] = 150;
        contributions[0xf5a5cf6eaD5BBf4f03f3F3779d0F6c1a0d841211] = 150;
        contributions[0xc4e9ac4D7D95aA101cA8A0EabEAd26069A5dE88A] = 500;
        contributions[0xAbeb2d7bf8FA01a0883fe3b8c6849aff42B075B9] = 1500;
        contributions[0xe90d55fD687cE6C3601053aF4065eE5bAD4bECF7] = 1750;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function claimContribution () external {
        require(getState() == 3, "Sale is not over");
        if (teamClaims == false) {
            teamClaims = true;
            revenue = address(this).balance;
        }
        uint256 amount = (contributions[msg.sender] * revenue) / 10000;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // states: 0="Not started", 1="Presale", 2="Public sale", 3="Sale over"
    function getState () public view returns(uint256 state) {
        if(block.timestamp > END_DATE) {
            state = 3;
        } else if (block.timestamp < END_DATE && block.timestamp > PUBLIC_DATE) {
            state = 2;
        } else if (block.timestamp < PUBLIC_DATE && block.timestamp > PRESALE_DATE) {
            state = 1;
        } else if (block.timestamp < PRESALE_DATE) {
            state = 0;
        }
    }

    function reserveClaim(
        uint256 _amount,
        uint256 _total,
        bytes32[] calldata _proof
    ) external {
        require(_verify(_leaf(msg.sender, _total), rootReserve, _proof),"Invalid merkle proof");
        require(getState() == 1, "Not my tempo");
        require(_amount + reserveClaims[msg.sender] <= _total, "Exceeds max allowed");
        reserveClaims[msg.sender] += _amount;
        totalClaimed += _amount;
        _safeMint(msg.sender, _amount);
    }

    function activistMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
    {
        require(
            _verify(_activistLeaf(msg.sender), rootActivist, _proof),
            "Invalid merkle proof"
        );
        require(msg.value == (_amount * ACTIVIST_PRICE), "Wrong amount.");
        require(getState() == 1, "Not my tempo");
        require(_amount + totalActivistMint[msg.sender] <= MAX_PER_WALLET, "Exceeds max allowed");
        require(_amount + totalMinted() <= MAX_AMOUNT, "Exceeds max amount");
        uint256 desired = totalMinted() + _amount;
        uint256 threshold = SOFT_CAP + totalClaimed;
        require(desired <= threshold, "Can't grab reserved assets");
        totalActivistMint[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external payable {
        require(_amount <= MAX_PER_TX, "Only 10 per tx");
        require(_amount + totalMinted() <= MAX_AMOUNT, "Exceeds max amount");
        require(msg.value == (_amount * PUBLIC_PRICE), "Wrong amount");
        require(getState() == 2, "Not my tempo");
        _safeMint(msg.sender, _amount);
    }

    function _leaf(address _account, uint256 _amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account, _amount));
    }

    function _activistLeaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(
        bytes32 leaf,
        bytes32 _root,
        bytes32[] memory _proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, leaf);
    }

    function setActivistRoot(bytes32 _root) external onlyOwner {
        rootActivist = _root;
    }

    function setReserveRoot(bytes32 _root) external onlyOwner {
        rootReserve = _root;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (revealed == false) {
            return baseURI_;
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function reveal(string memory __baseURI) external onlyOwner {
        require(revealed == false, "It's been revealed already.");
        baseURI_ = __baseURI;
        revealed = true;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function burn(uint256 _tokenId, bool _approvalCheck) public {
        _burn(_tokenId, _approvalCheck);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            PROXY_REGISTRY
        );
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

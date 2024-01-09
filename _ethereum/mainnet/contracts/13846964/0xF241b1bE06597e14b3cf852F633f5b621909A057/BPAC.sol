// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./MerkleProof.sol";

// Baby Princess Ape Club(B.P.A.C)
contract BPAC is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string baseURI;

    // Token name
    string internal ext_name;

    // Token symbol
    string internal ext_symbol;

    struct PaymentOption {
        address token_addr;
        uint256 price;
    }

    struct PaymentInfo {
        // A token address for payment:
        // 1. ERC-20 token address
        // 2. adderss(0) for ETH
        address token_addr;
        uint256 price;
        uint256 receivable_amount;
    }

    // public sale purchage limit: maxmimum number of NFT(s) user can buy
    uint32 public_sale_purchase_limit;

    // `presale limit` is part of the merkle proof, so it is not here

    // total NFT(s) in stock
    uint32 total_quantity;

    // whitelist sale start time
    uint32 presale_start_time;

    // public sale start time
    uint32 public_sale_start_time;

    // public sale end time
    uint32 public_sale_end_time;

    // total number of NFT(s) sold
    uint32 sold_quantity;

    // payment info, price/tokens, etc
    PaymentInfo[] payment_list;

    // treasury address, receiving ETH/tokens
    address payable treasury;

    // how many NFT(s) purchased: public sale
    mapping(address => uint32) public public_purchased_by_addr;

    // how many NFT(s) purchased: presale
    mapping(address => uint32) public presale_purchased_by_addr;

    // smart contract admin
    mapping(address => bool) public admin;

    // whitelist sale end time
    uint32 presale_end_time;

    // not used anymore, just leave it here to keep `storage` compatible
    uint32 reveal_start_time;

    mapping(bytes32 => bool) public merkleRoots;

    uint256 presale_price;

    function initialize(
        uint32 _public_sale_purchase_limit,
        uint32 _total_quantity,
        uint32 _presale_start_time,
        uint32 _presale_end_time,
        uint32 _public_sale_start_time,
        uint32 _public_sale_end_time,
        PaymentOption[] calldata _payment,
        bytes32 _merkle_root,
        address payable _treasury,
        uint256 _presale_price
    )
        public
        initializer
    {
        // workaround: stack too deep
        baseURI = "https://raw.githubusercontent.com/PrincessApeClub/NFTAsset/master/";
        ext_name = "Baby Princess Ape Club";
        ext_symbol = "BPAC";
        __ERC721_init(ext_name, ext_symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        public_sale_purchase_limit = _public_sale_purchase_limit;
        total_quantity = _total_quantity;
        presale_start_time = _presale_start_time;
        presale_end_time = _presale_end_time;
        public_sale_start_time = _public_sale_start_time;
        public_sale_end_time = _public_sale_end_time;
        for (uint256 i = 0; i < _payment.length; i++) {
            if (_payment[i].token_addr != address(0)) {
                require(IERC20(_payment[i].token_addr).totalSupply() > 0, "invalid ERC20 address");
            }
            PaymentInfo memory payment = PaymentInfo(_payment[i].token_addr, _payment[i].price, 0);
            payment_list.push(payment);
        }
        merkleRoots[_merkle_root] = true;
        treasury = _treasury;
        presale_price = _presale_price;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, "json/", StringsUpgradeable.toString(tokenId), ".json"));
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    function name() public view virtual override returns (string memory) {
        return ext_name;
    }

    function symbol() public view virtual override returns (string memory) {
        return ext_symbol;
    }

    function publicSaleMint(uint8 number_of_nft)
        external
        payable
    {
        require (public_sale_start_time < block.timestamp, "public sale not started");
        require (public_sale_end_time >= block.timestamp, "public sale ended");
        _mint(number_of_nft, true, payment_list[0].price);
    }

    function presaleMint(
        uint256 index,
        uint256 amount,
        bytes32 root,
        bytes32[] calldata proof
    )
        external
        payable
    {
        // for this project, presale: `only 1 for each wallet`
        require (presale_start_time < block.timestamp, "presale not started");
        require (presale_end_time >= block.timestamp, "presale expired");
        require (merkleRoots[root], "invalid merkle root");

        // validate whitelist user
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(MerkleProof.verify(proof, root, leaf), "not whitelisted");

        require(presale_purchased_by_addr[msg.sender] < amount, "exceeds personal limit");
        presale_purchased_by_addr[msg.sender] += 1;
        _mint(1, false, presale_price);
    }

    function _mint(
        uint8 number_of_nft,
        bool public_sale,
        uint256 price
    )
        internal
    {
        require(tx.origin == msg.sender, "not real user");

        uint32 bought_number = public_purchased_by_addr[msg.sender];
        if (public_sale) {
            require((bought_number + number_of_nft) <= public_sale_purchase_limit, "exceeds public sale limit");
        }
        require(sold_quantity < total_quantity, "no NFT left");
        uint8 actual_number_of_nft = number_of_nft;
        if ((sold_quantity + number_of_nft) > total_quantity) {
            actual_number_of_nft = uint8(total_quantity - sold_quantity);
        }
        {
            uint256 total = price;
            total = total.mul(actual_number_of_nft);

            require(msg.value >= total, "not enough ETH");
            uint256 eth_to_refund = msg.value - total;
            if ((number_of_nft > actual_number_of_nft) && (eth_to_refund > 0)) {
                address payable addr = payable(_msgSender());
                addr.transfer(eth_to_refund);
            }
            {
                // transfer to treasury
                treasury.transfer(total);
            }

            payment_list[0].receivable_amount += total;
        }
        {
            for (uint256 i = 0; i < actual_number_of_nft; i++) {
                _safeMint(_msgSender(), totalSupply());
            }
            if (public_sale) {
                public_purchased_by_addr[msg.sender] = bought_number + actual_number_of_nft;
            }
            sold_quantity = sold_quantity + actual_number_of_nft;
        }
    }

    function adminMint(uint256 count) external onlyAdmin {
        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
    }

    function getNFTInfo()
        external
        view
        returns (
            address _owner,
            string memory _name,
            uint32 _public_sale_purchase_limit,
            uint32 _total_quantity,
            uint32 _presale_start_time,
            uint32 _presale_end_time,
            uint32 _public_sale_start_time,
            uint32 _public_sale_end_time,
            uint32 _sold_quantity,
            PaymentInfo[] memory _payment_list,
            uint256 _presale_price
        )
    {
        _owner = owner();
        _name = name();
        _public_sale_purchase_limit = public_sale_purchase_limit;
        _total_quantity = total_quantity;
        _presale_start_time = presale_start_time;
        _presale_end_time = presale_end_time;
        _public_sale_start_time = public_sale_start_time;
        _public_sale_end_time = public_sale_end_time;
        _sold_quantity = sold_quantity;
        _payment_list = payment_list;
        _presale_price = presale_price;
    }

    function setTime(
        uint32 _presale_start_time,
        uint32 _presale_end_time,
        uint32 _public_sale_start_time,
        uint32 _public_sale_end_time
    ) external onlyAdmin {
        presale_start_time = _presale_start_time;
        presale_end_time = _presale_end_time;
        public_sale_start_time = _public_sale_start_time;
        public_sale_end_time = _public_sale_end_time;
    }

    // reveal mystery box
    function setBaseURI(string memory _baseURI_) external onlyAdmin {
        baseURI = _baseURI_;
    }

    function setName(string memory _name) external onlyAdmin {
        ext_name = _name;
    }

    function setSymbol(string memory _symbol) external onlyAdmin {
        ext_symbol = _symbol;
    }

    function setPresalePrice(uint256 _presale_price) external onlyAdmin {
        presale_price = _presale_price;
    }

    function setMerkleRoot(bytes32 root) external onlyAdmin {
        merkleRoots[root] = true;
    }

    modifier onlyAdmin() {
        require(owner() == _msgSender() || admin[_msgSender()], "caller not admin");
        _;
    }

    function addAdmin(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            admin[addrs[i]] = true;
        }
    }

    function removeAdmin(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            admin[addrs[i]] = false;
        }
    }

    function setTotalSuply(uint32 _total_quantity) external onlyOwner {
        total_quantity = _total_quantity;
    }
}

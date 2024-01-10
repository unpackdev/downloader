// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**************************************************
 *
 *                       . . . .
 *                       ,`,`,`,`,
 * . . . .               `\`\`\`\;
 * `\`\`\`\`,            ~|;!;!;\!
 *  ~\;\;\;\|\          (--,!!!~`!       .
 * (--,\\\===~\         (--,|||~`!     ./
 *  (--,\\\===~\         `,-,~,=,:. _,//
 *   (--,\\\==~`\        ~-=~-.---|\;/J,
 *    (--,\\\((```==.    ~'`~/       a |
 *      (-,.\\('('(`\\.  ~'=~|     \_.  \
 *         (,--(,(,(,'\\. ~'=|       \\_;>
 *           (,-( ,(,(,;\\ ~=/        \
 *           (,-/ (.(.(,;\\,/          )
 *            (,--/,;,;,;,\\         ./------.
 *              (==,-;-'`;'         /_,----`. \
 *      ,.--_,__.-'                    `--.  ` \
 *     (='~-_,--/        ,       ,!,___--. \  \_)
 *    (-/~(     |         \   ,_-         | ) /_|
 *    (~/((\    )\._,      |-'         _,/ /
 *     \\))))  /   ./~.    |           \_\;
 *  ,__/////  /   /    )  /
 *   '===~'   |  |    (, <.
 *            / /       \. \
 *          _/ /          \_\
 *         /_!/            >_\
 * ------------------------------------------------
 *
 * Unifriends NFT
 * https://unifriends.io
 * Developed By: @sbmitchell.eth
 *
 **************************************************/

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./base64.sol";
import "./UnifriendsRenderer.sol";
import "./ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Unifriends is ERC721Enumerable, Ownable {
    using UnifriendsRenderer for *;

    string constant NAME = "Unifriends";
    string constant SYMBOL = "Unifriends";
    uint256 public constant MAX_PER_TX = 11;

    uint256 public constant whitelistPriceInWei = 0.069420 ether;
    uint256 public publicPriceInWei = 0.1337 ether;

    string public baseURI;
    string public animationURI;
    address public proxyRegistryAddress;
    address public treasury;
    bytes32 public whitelistMerkleRoot;
    uint256 public maxSupply;
    uint256 public reserves = 251;
    uint256 mintNonce = 0;
    bool public isRevealed = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    constructor(
        string memory _baseURI,
        string memory _animationURI,
        address _proxyRegistryAddress,
        address _treasury
    ) ERC721(NAME, SYMBOL) {
        baseURI = _baseURI;
        animationURI = _animationURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        treasury = payable(_treasury);
    }

    /*
        Derives a leaf node for the merkle tree which aligns w/ the algorithm off-chain to derive merkle root
    */
    function _toLeaf(address _address, uint256 _allowance)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    string(abi.encodePacked(_address)),
                    Strings.toString(_allowance)
                )
            );
    }

    /*
       Mint a unifriend NFT w/ pseudo-randomness

       - Basis mint was 53k gas but added seeds mapping which increased gas to ~80-85k
       - Chainlink VRF was initially implemented but drove mint costs from 80k -> 170k gas which we found unacceptable for this use case
         Note: We will use provably random in longer lasting contracts involving game mechanics
       - `tokenIdToRandomNumber` stores a random number to tokenId to use a basis for tokenURI rendering

       Avg gas limit for public mint ~85-90k
       Avg gas limit for whitelist mint ~120k due to merkle proof
    */
    function _mint(address to, uint256 tokenId) internal virtual override {
        require(!_exists(tokenId), "Token already minted");
        mintNonce++;
        _owners.push(to);
        tokenIdToRandomNumber[tokenId] = pseudorandom(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function setPublicPriceInWei(uint256 _publicPriceInWei) public onlyOwner {
        publicPriceInWei = _publicPriceInWei;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    function setReserves(uint256 _reserves) public onlyOwner {
        reserves = _reserves;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function toggleRevealed() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function setAnimationURI(string memory _animationURI) public onlyOwner {
        animationURI = _animationURI;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function togglePublicSale(uint256 _maxSupply) external onlyOwner {
        delete whitelistMerkleRoot;
        maxSupply = _maxSupply;
    }

    function preRevealMetadata() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                UnifriendsRenderer.toJSONProperty(
                                    "name",
                                    "Hidden"
                                ),
                                ",",
                                '"attributes": []',
                                ",",
                                UnifriendsRenderer.toJSONProperty(
                                    "image",
                                    baseURI
                                ),
                                ",",
                                UnifriendsRenderer.toJSONProperty(
                                    "external_url",
                                    baseURI
                                ),
                                ",",
                                UnifriendsRenderer.toJSONProperty(
                                    "animation_url",
                                    baseURI
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*
        Derived on-chain metadata based on randomness seed
        Returns a base64 encoded json string
        `image` asset will still live in IPFS based on `baseURI` set
        `attributes` are derived based on seed within the `UnifriendsRenderer` library
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");

        if (!isRevealed) {
            return preRevealMetadata();
        }

        return
            UnifriendsRenderer.base64TokenURI(
                tokenId,
                baseURI,
                animationURI,
                tokenIdToRandomNumber[tokenId]
            );
    }

    /*
       Founder and legendary collection
       Can only run before whitelist sale
       First 10 -> legndaries which will be distributed via DAO or as giveaways
       10-110 -> Giveaways/Gifted NFTs for first 100 based on collabs and discord contests
       110-250 -> Team, mods, etc
    */
    function collectReserves(uint256 amount) external onlyOwner {
        require(_owners.length + amount < reserves, "Reserves already taken.");
        uint256 totalSupply = _owners.length;
        for (uint256 i = 0; i < amount; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    /*
       Whitelist sale - only valid with merkle tree root set
       Avg gas limit for public mint ~120k-130k due to merkle proof
    */
    function whitelistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        require(
            count * whitelistPriceInWei == msg.value,
            "Invalid funds provided."
        );

        require(
            MerkleProof.verify(
                proof,
                whitelistMerkleRoot,
                _toLeaf(_msgSender(), allowance)
            ),
            "Invalid Merkle Tree proof supplied."
        );

        require(
            addressToMinted[_msgSender()] + count <= allowance,
            "Exceeds whitelist supply."
        );

        addressToMinted[_msgSender()] += count;

        uint256 totalSupply = _owners.length;

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    /*
       Public sale - only valid after whitelist sale is complete
       Avg gas limit for public mint ~85-90k
    */
    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;

        require(totalSupply + count < maxSupply, "Excedes max supply.");

        require(count < MAX_PER_TX, "Exceeds max per transaction.");

        require(
            count * publicPriceInWei == msg.value,
            "Invalid funds provided."
        );

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to treasury.");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    /*
       OS Pre-approvals and future project integration approvals for extensibility
    */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );

        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    /*
     * Random enough for all intents and purposes of this NFT
     * I would be more concerned if it were more of a recurring lottery.
     */
    function pseudorandom(address to, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        to,
                        Strings.toString(mintNonce),
                        Strings.toString(tokenId)
                    )
                )
            );
    }
}

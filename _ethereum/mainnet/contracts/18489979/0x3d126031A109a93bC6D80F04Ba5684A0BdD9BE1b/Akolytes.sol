// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./Owned.sol";
import "./ERC721.sol";

import "./ERC2981.sol";
import "./IERC2981.sol";
import "./Strings.sol";

import "./IERC721.sol";
import "./ICurve.sol";
import "./LSSVMPair.sol";
import "./ERC20.sol";

import "./PairFactoryLike.sol";
import "./RoyaltyHandler.sol";
import "./ERC721Minimal.sol";

import "./StringLib.sol";
import "./Base64.sol";

interface IMarkov {
    function speak(uint256 magic, uint256 duration) external view returns (string memory s);
}

contract Akolytes is ERC721Minimal, ERC2981, Owned {
    /*//////////////////////////////////////////////////////////////
                  Struct
    //////////////////////////////////////////////////////////////*/

    struct OwnerOfWithData {
        address owner;
        uint96 lastTransferTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                      Libraries
    //////////////////////////////////////////////////////////////*/

    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;
    using StringLib for string;
    using StringLib for StringLib.slice;

    /*//////////////////////////////////////////////////////////////
                       Error
    //////////////////////////////////////////////////////////////*/

    error Cooldown();
    error Monless();
    error Akoless();
    error Scarce();
    error TooHigh();
    error NoYeet();
    error NoZero();
    error WrongFrom();
    error Unauth();

    /*//////////////////////////////////////////////////////////////
                       Events
    //////////////////////////////////////////////////////////////*/

    event NewRoyalty(uint256 newRoyalty);
    event RoyaltiesClaimed(address token, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                         Constants
    //////////////////////////////////////////////////////////////*/

    uint256 constant TOTAL_AKOLS = 512;
    string private constant ARWEAVE_HASH = "XxDgZs6LRWDmzQIfR0Lssic8a4k3eQbyaosttObj7Ec";

    // Name generation process: 1 random from s1, 1 random from s2, and then 0-2 from s3
    string private constant s1 = "Cth,Az,Ap,Ch,Bl,Gh,Gl,Kr,M,Nl,Ny,D,Xy,Rh,U,Bl,Cz,En,Fz,H,Il,J,Jh,Y,YvK,Z,Zh,Sl,T,O,U,Ub,Os,Eh,Sh";
    uint256 private constant s1Length = 35;

    string private constant s2 = "ak,al,es,et,id,il,id,oo,or,ux,un,ap,ek,ex,in,ol,up,-af,-aw,'et,'ed,-in,-is,'od,-at,-of";
    uint256 private constant s2Length = 26;

    string private constant s3 = "ag,al,on,ak,ash,a,ber,bal,buk,cla,ced,ck,dar,dru,est,end,fli,fa,-fur,gen,ga,his,ha,ilk,in,-in,ju,ja,-ki,ll,lo,mo,-mu,ma,no,r,ss,sh,sto,ta,tha,un,vy,va,wy,wu,y,yy,z,zs,ton,gon,-man,lu,get,har,uz,ek,ec,-s";
    uint256 private constant s3Length = 60;

    // Max number of times we grab a syllable from s3
    uint256 private constant maxS3Iters = 2;

    // Max 10% royalty
    uint256 private constant MAX_ROYALTY = 1000;

    // Get ur akolytes before i yeet them
    uint256 private constant MIN_YEET_DELAY = 7 days;

    // For metadata
    uint256 constant DURATION = 42;

    /*//////////////////////////////////////////////////////////////
                         Immutables
    //////////////////////////////////////////////////////////////*/

    // Immutable contract reference vars
    address private immutable MONS;
    address private immutable SUDO_FACTORY;
    address private immutable GDA_ADDRESS;
    address private immutable LINEAR_ADDRESS;
    address private immutable XMON_ADDRESS;
    address payable public immutable ROYALTY_HANDER;
    uint256 private immutable START_TIME;

    // Babble babble
    IMarkov public immutable MARKOV;

    /*//////////////////////////////////////////////////////////////
                         Storage
    //////////////////////////////////////////////////////////////*/

    // Mapping of (id, 256 bits) => (owner address, 160 bits | unlockDate timestamp, 96 bits)
    mapping(uint256 => OwnerOfWithData) public ownerOfWithData;

    // Mapping of (token address, 160 bits | akolyte id, 96 bits) => amount already claimed for that id
    mapping(uint256 => uint256) public royaltyClaimedPerId;

    // Mapping of royalty amounts accumulated in total per royalty token
    mapping(address => uint256) public royaltyAccumulatedPerTokenType;

    // Seed overrides for speaking
    mapping(uint256 => uint256) public markovSeed;

    /*//////////////////////////////////////////////////////////////
                         Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _mons, address _factory, address _markov, address _gda, address _xmon, address _linear)
        ERC721Minimal("Akolytes", "AKOL")
        Owned(msg.sender)
    {
        MONS = _mons;
        SUDO_FACTORY = _factory;
        ROYALTY_HANDER = payable(address(new RoyaltyHandler()));
        START_TIME = block.timestamp;
        MARKOV = IMarkov(_markov);
        GDA_ADDRESS = _gda;
        XMON_ADDRESS = _xmon;
        LINEAR_ADDRESS = _linear;

        // 5% royalty, set to this address
        _setDefaultRoyalty(address(this), 500);
    }

    /*//////////////////////////////////////////////////////////////
                 User Facing
    //////////////////////////////////////////////////////////////*/

    // Claim for mons
    function tap_to_summon_akolytes(uint256[] calldata ids) public {
        for (uint256 i; i < ids.length; ++i) {
            if (ERC721(MONS).ownerOf(ids[i]) != msg.sender) {
                revert Monless();
            }
        }
        _mint(msg.sender, ids);
    }

    // Claims royalties accrued for owned IDs
    function claimRoyalties(address royaltyToken, uint256[] calldata ids) public returns (uint256 royaltiesReceived) {
        uint256 idLength = ids.length;
        accumulateRoyalty(royaltyToken);
        uint256 amountPerId = royaltyAccumulatedPerTokenType[royaltyToken] / TOTAL_AKOLS;
        for (uint256 i; i < idLength; ++i) {
            if (ownerOf(ids[i]) == msg.sender) {
                uint256 idAndTokenKey = uint256(uint160(royaltyToken)) << 96 | ids[i];

                // This should undeflow if already claimed to the maximum amount
                uint256 royaltyToAdd = amountPerId - royaltyClaimedPerId[idAndTokenKey];

                // If we are sending a royalty amount, then keep track of the amount
                if (royaltyToAdd > 0) {
                    royaltiesReceived += royaltyToAdd;
                    royaltyClaimedPerId[idAndTokenKey] = amountPerId;
                }
            } else {
                revert Akoless();
            }
        }
        // If native token
        if (royaltyToken == address(0)) {
            RoyaltyHandler(ROYALTY_HANDER).sendETH(payable(msg.sender), royaltiesReceived);
        }
        // Otherwise, do ERC20 transfer
        else {
            RoyaltyHandler(ROYALTY_HANDER).sendERC20(msg.sender, royaltyToken, royaltiesReceived);
        }
        return royaltiesReceived;
    }

    // Accumulates royalties accrued
    function accumulateRoyalty(address royaltyToken) public {
        // Handle native token royalties
        if (royaltyToken == address(0)) {
            // Send balance and accumulate
            uint256 ethBalance = address(this).balance;
            royaltyAccumulatedPerTokenType[address(0)] += ethBalance;
            ROYALTY_HANDER.safeTransferETH(ethBalance);
            emit RoyaltiesClaimed(royaltyToken, ethBalance);
        } else {
            uint256 tokenBalance = ERC20(royaltyToken).balanceOf(address(this));
            royaltyAccumulatedPerTokenType[royaltyToken] += tokenBalance;
            ERC20(royaltyToken).safeTransfer(ROYALTY_HANDER, tokenBalance);
            emit RoyaltiesClaimed(royaltyToken, tokenBalance);
        }
    }

    function recast(uint256 id, uint256 seed) external payable {
        require(msg.value == 0.01 ether);
        require(ownerOf(id) == msg.sender);
        markovSeed[id] = seed;
    }

    /*//////////////////////////////////////////////////////////////
                   IERC721 Compliance
    //////////////////////////////////////////////////////////////*/

    // Overrides both ERC721 and ERC2981
    function supportsInterface(bytes4 interfaceId) public pure override(ERC2981, ERC721Minimal) returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == type(IERC2981).interfaceId // ERC165 interface for IERC2981
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function ownerOf(uint256 id) public view override returns (address owner) {
        owner = ownerOfWithData[id].owner;
    }

    // Transfers and sets time delay if to/from a non-sudo pool
    function transferFrom(address from, address to, uint256 id) public override {
        if (from != ownerOf(id)) {
            revert WrongFrom();
        }
        if (to == address(0)) {
            revert NoZero();
        }
        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id]) {
            revert Unauth();
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        delete getApproved[id];
        uint256 timestamp = block.timestamp;

        // Always allow transfer if one of the recipients is a sudo pool
        bool isPair;
        try PairFactoryLike(SUDO_FACTORY).isValidPair(from) returns (bool result) {
            isPair = result;
        } catch {}
        if (!isPair) {
            try PairFactoryLike(SUDO_FACTORY).isValidPair(to) returns (bool result) {
                isPair = result;
            } catch {}
        }
        // If either to or from a pool, always allow it
        if (isPair) {
            ownerOfWithData[id].owner = to;
        }
        // If one of the two recipients is not a sudo pool
        else {
            // Check if earlier than allowed, if so, then revert
            if (timestamp < ownerOfWithData[id].lastTransferTimestamp) {
                revert Cooldown();
            }
            // If it is past the cooldown, then we set a new cooldown, and let the transfer go through
            ownerOfWithData[id] = OwnerOfWithData({owner: to, lastTransferTimestamp: uint96(timestamp + 7 days)});
        }
        emit Transfer(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                  Generative Metadata
    //////////////////////////////////////////////////////////////*/

    function getName(uint256 seed) public pure returns (string memory) {
        uint256 rng = seed;
        // Get uniform from s1
        string memory nameS1 = _getItemFromCSV(s1, rng % s1Length);
        // Update seed
        rng = uint256(keccak256(abi.encode(rng)));
        // Get uniform from s2
        string memory nameS2 = _getItemFromCSV(s2, rng % s2Length);
        // Concatenate the two
        string memory name = string(abi.encodePacked(nameS1, nameS2));
        // Update seed
        rng = uint256(keccak256(abi.encode(rng)));
        // Add any s3 syllables (if possible)
        for (uint256 i = 0; i < rng % (maxS3Iters + 1); i++) {
            string memory nameS3 = _getItemFromCSV(s3, rng % s3Length);
            rng = uint256(keccak256(abi.encode(rng)));
            name = string(abi.encodePacked(name, nameS3));
        }
        return name;
    }

    // @dev Don't worry about anything from here until the tokenURI
    function _getItemFromCSV(string memory str, uint256 index) internal pure returns (string memory) {
        StringLib.slice memory strSlice = str.toSlice();
        string memory separatorStr = ",";
        StringLib.slice memory separator = separatorStr.toSlice();
        StringLib.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function d1(uint256 seed) internal pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        uint256 diff = end + 1 - start;
        result = (seed % diff) + start;
    }

    function d2(uint256 seed) internal pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        uint256 subresult1 = d1(seed);
        uint256 seed2 = uint256(keccak256(abi.encode(seed, start, end)));
        uint256 subresult2 = d1(seed2);
        result = (subresult1 + subresult2) / 2;
    }

    function d3(uint256 seed) internal pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        uint256 midpoint = (start + end) / 2;
        uint256 d2Value = d2(seed);
        if (d2Value >= midpoint) {
            result = end - (d2Value - midpoint);
        } else {
            result = start + (midpoint - d2Value);
        }
    }

    function d4(uint256 seed) internal pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        result = d1(seed);
        if (result % 2 == 1) {
            result = d1(uint256(keccak256(abi.encode(seed, start, end))));
        }
    }

    function d5(uint256 seed) internal pure returns (uint256 result) {
        uint256 selector = seed % 4;
        uint256 newSeed = uint256(keccak256(abi.encode(seed / d1(seed))));
        if (selector == 0) {
            result = d3(newSeed);
        } else if (selector == 1) {
            result = d1(newSeed);
        } else if (selector == 2) {
            result = d2(newSeed);
        } else if (selector == 3) {}
        result = d4(newSeed);
    }

    function d6(uint256 id) internal pure returns (uint256) {
        if (id == 0) {
            return 0;
        }
        for (uint256 i = 2; i <= id / 2; i++) {
            uint256 result = id - ((id / i) * i);
            if (result == 0) {
                return 1;
            }
        }
        return 2;
    }

    function secondD(uint256 seed, uint256 id) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '"trait_type": "4tiart",' '"value": "',
                Strings.toString(d4(seed)),
                '"},{',
                '"trait_type": "V",' '"value": "',
                Strings.toString(d5(seed)),
                '"},{',
                '"trait_type": "-- . . . .",' '"value": "',
                Strings.toString(d6(id)),
                '"}'
            )
        );
    }

    function getD(uint256 seed, uint256 id) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "{",
                '"trait_type": "TRAIT ONE",' '"value": "',
                Strings.toString(d1(seed)),
                '"},{',
                '"trait_type": "7R417_2",' '"value": "',
                Strings.toString(d2(seed)),
                '"},{',
                '"trait_type": "trait3",' '"value": "',
                Strings.toString(d3(seed)),
                '"},{',
                secondD(seed, id)
            )
        );
    }

    function getMagic(uint256 id) public view returns (uint256) {
        if (markovSeed[id] == 0) {
          return uint256(keccak256(abi.encode(id)));
        }
        else {
          return uint256(keccak256(abi.encode(id, markovSeed[id])));
        }
    }

    // Handles metadata from arweave hash, constructs name and metadata
    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encode(id, uint160(SUDO_FACTORY))));
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            getName(id),
                            '", "description":"',
                            MARKOV.speak(getMagic(id), DURATION),
                            '", "image": "',
                            "ar://",
                            ARWEAVE_HASH,
                            "/m",
                            Strings.toString(id),
                            ".gif",
                            '", "attributes": [',
                            getD(seed, id),
                            "]",
                            "}"
                        )
                    )
                )
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                      Mint x Pool 
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256[] memory ids) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");
        uint256 numIds = ids.length;
        unchecked {
            _balanceOf[to] += numIds;
        }
        for (uint256 i; i < numIds;) {
            uint256 id = ids[i];
            if (id >= TOTAL_AKOLS) {
                revert Scarce();
            }
            require(ownerOf(id) == address(0), "ALREADY_MINTED");
            ownerOfWithData[id].owner = to;
            emit Transfer(address(0), to, id);
            unchecked {
                ++i;
            }
        }
    }

    function initPools() public onlyOwner returns (address gdaPool, address tradePool){
        uint256[] memory empty = new uint256[](0);
        gdaPool = address(
            PairFactoryLike(SUDO_FACTORY).createPairERC721ERC20(
                PairFactoryLike.CreateERC721ERC20PairParams({
                    token: ERC20(XMON_ADDRESS),
                    nft: IERC721(address(this)),
                    bondingCurve: ICurve(GDA_ADDRESS),
                    assetRecipient: payable(address(0)),
                    poolType: LSSVMPair.PoolType.NFT,
                    delta: ((uint128(1500000000) << 88)) | ((uint128(11574) << 48)) | uint128(block.timestamp),
                    fee: 0,
                    spotPrice: 5 ether,
                    propertyChecker: address(0),
                    initialNFTIDs: empty,
                    initialTokenBalance: 0
                })
            )
        );
        tradePool = address(
            PairFactoryLike(SUDO_FACTORY).createPairERC721ETH(
                IERC721(address(this)),
                ICurve(LINEAR_ADDRESS),
                payable(address(this)),
                LSSVMPair.PoolType.TRADE,
                0.0128 ether,
                0,
                0.0128 ether,
                address(0),
                empty
            )
        );
        uint256[] memory akolytesToDeposit = new uint256[](69);
        for (uint256 i; i < 69;) {
            akolytesToDeposit[i] = 341 + i;
            unchecked {
                ++i;
            }
        }
        _mint(gdaPool, akolytesToDeposit);
        akolytesToDeposit = new uint256[](102);
        for (uint256 i; i < 102;) {
            akolytesToDeposit[i] = 410 + i;
            unchecked {
                ++i;
            }
        }
        _mint(tradePool, akolytesToDeposit);
    }

    /*//////////////////////////////////////////////////////////////
                        Conveniences
    //////////////////////////////////////////////////////////////*/

    function idsForAddress(address a) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(a);
        uint256[] memory ids = new uint256[](balance);
        if (balance > 0) {
            uint256 counter = 0;
            for (uint256 i; i < TOTAL_AKOLS;) {
                address owner = ownerOfWithData[i].owner;
                if (owner == a) {
                    ids[counter] = i;
                    unchecked {
                        ++counter;
                    }
                    if (counter == balance) {
                        return ids;
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
        return ids;
    }

    function royaltiesAccrued(uint256[] memory ids, address royaltyToken)
        external
        view
        returns (uint256[] memory royaltyPerId)
    {
        uint256 idLength = ids.length;
        royaltyPerId = new uint256[](idLength);
        uint256 amountPerId = royaltyAccumulatedPerTokenType[royaltyToken] / TOTAL_AKOLS;
        for (uint256 i; i < idLength; ++i) {
            uint256 idAndTokenKey = uint256(uint160(royaltyToken)) << 96 | ids[i];
            royaltyPerId[i] = amountPerId - royaltyClaimedPerId[idAndTokenKey];
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Tweaks
    //////////////////////////////////////////////////////////////*/

    function adjustRoyalty(uint96 newRoyalty) public onlyOwner {
        if (newRoyalty <= MAX_ROYALTY) {
            _setDefaultRoyalty(address(this), newRoyalty);
            emit NewRoyalty(newRoyalty);
        } else {
            revert TooHigh();
        }
    }

    function yeet(uint256[] calldata ids) public onlyOwner {
        // Can only yeet after min yeet delay
        if (block.timestamp < START_TIME + MIN_YEET_DELAY) {
            revert NoYeet();
        }

        // Can only yeet below 341 (ensures no supply rug)
        uint256 numIds = ids.length;
        for (uint256 i; i < numIds; ++i) {
            if (ids[i] >= 341) {
                revert Scarce();
            }
        }

        _mint(msg.sender, ids);
    }

    // Receive ETH
    receive() external payable {}
}

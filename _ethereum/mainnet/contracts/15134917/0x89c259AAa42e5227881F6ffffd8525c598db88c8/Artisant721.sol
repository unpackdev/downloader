// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.4;


import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./AddressString.sol";

import "./console.sol";

contract Artisant721 is OwnableUpgradeable, ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable {
    struct MintClass {
        uint32 whitelistAt;
        uint32 publicAt;
        uint256 price;
        uint64 nextId;
        uint64 startId;
        uint64 maxId;
        uint64 maxPerAddress;
        string baseURI;
        uint256 classId;
    }

    uint8 public nextClassId;
    mapping(uint256=>MintClass) public classes;

    address public signer;

    mapping(uint256=>uint256) packedMintedPerAddr;

    function initialize(string memory name_, string memory symbol_)
    initializer
    public
    {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function sudoUpdateSigner(
        address _signer
    )
    onlyOwner
    public
    {
        signer = _signer;
    }

    function sudoUpdateClassId(
        uint8 classId,
        uint32 whitelistAt,
        uint32 publicAt,
        uint256 price,
        uint64 maxPerAddress,
        string memory baseURI
    )
    onlyOwner
    public
    {
        MintClass memory class = classes[classId];
        require(class.maxId > 0, "ERR_CLASS");
        require(nextClassId<=255, "ERR_OVERFLOW");
        require(publicAt > 0, "ERR_PUBLIC");
        require(maxPerAddress < (2**16 - 1), "ERR_MAX_PER_ADDR");
        require(bytes(baseURI).length > 0, "ERR_BASE_URI");
        class.whitelistAt = whitelistAt;
        class.publicAt = publicAt;
        class.price = price;
        class.maxPerAddress = maxPerAddress;
        class.baseURI = baseURI;
        classes[classId] = class;
    }

    function sudoInitClassId(
        uint32 whitelistAt,
        uint32 publicAt,
        uint256 price,
        uint64 amount,
        uint64 maxPerAddress,
        string memory baseURI
    )
    onlyOwner
    public
    {
        require(nextClassId<255, "ERR_OVERFLOW");
        require(publicAt > 0, "ERR_PUBLIC");
        require(amount > 0, "ERR_MAX_ID");
        require(maxPerAddress < (2**16 - 1), "ERR_MAX_PER_ADDR");
        require(bytes(baseURI).length > 0, "ERR_BASE_URI");
        uint64 startId = 0;
        if(nextClassId > 0) {
            startId = classes[nextClassId - 1].maxId + 1;
        }
        classes[nextClassId] = MintClass({
            whitelistAt: whitelistAt,
            publicAt: publicAt,
            price: price,
            maxId: startId + amount - 1,
            startId: startId,
            nextId: startId,
            maxPerAddress: maxPerAddress,
            classId: nextClassId,
            baseURI: baseURI
        });
        nextClassId+=1;
    }

    function reserve(
        uint8 classId,
        address[] memory to,
        uint256[] memory quantities
    )
    external
    onlyOwner
    {
        MintClass memory class = classes[classId];
        require(class.maxId>0, "ERR_CLASS");

        require(to.length == quantities.length,
                "To length is not equal to quantities");

        for(uint256 idx=0; idx < to.length; idx++) {
            uint256 quantity = quantities[idx];
            address receiver = to[idx];
            require(
                class.nextId + quantity - 1 <= class.maxId,
                "not enough remaining reserved for sale to support desired mint amount"
            );

            require(
                numberMintedOfClass(receiver, uint8(classId)) + quantity <= class.maxPerAddress,
                "can not mint this many"
            );

            console.log("Reserve %d quantities %d for receiver %s", classId, quantity, receiver);
            for(uint256 idx2 = 0; idx2 < quantity; idx2++) {
                uint256 tokenId = class.nextId;
                console.log("_safeMint(%s,%d)", receiver, tokenId);
                _safeMint(receiver, tokenId);
                class.nextId+=1;
            }
            _incrementMintedOfClass(receiver, classId, quantity);
        }
        classes[classId] = class;
    }

    function mint(
        uint256 quantity,
        uint8 classId
    )
    external
    payable
    callerIsUser
    {
        MintClass memory class = classes[classId];
        require(class.maxId > 0, "ERR_CLASS");
        uint256 price = uint256(class.price);

        require(
            isSaleOn(price, class.publicAt),
            "public sale has not begun yet"
        );

        require(
            class.nextId + quantity - 1 <= class.maxId,
            "not enough remaining reserved for sale to support desired mint amount"
        );

        require(
            numberMintedOfClass(msg.sender, uint8(classId)) + quantity <= class.maxPerAddress,
            "can not mint this many"
        );

        for(uint256 idx = 0; idx < quantity; idx++) {
            uint256 tokenId = class.nextId++;
            _safeMint(msg.sender, tokenId);
        }
        _incrementMintedOfClass(msg.sender, classId, quantity);
        refundIfOver(price * quantity);
        classes[classId] = class;
    }

    function mintPrivateSale(
        uint256 quantity,
        uint8 signedClassId,
        uint256 signedPermittedMax,
        uint256 signedFreeMax,
        uint256 signedDiscount,
        bytes memory signature
    )
    external
    payable
    callerIsUser
    {
        MintClass memory class = classes[signedClassId];
        require(class.maxId>0, "ERR_CLASS");
        require(signedDiscount <= 10000, "ERR_DISCOUNT");
        uint256 price = uint256(class.price) / 10000 * (10000 - signedDiscount);

        require(
            isSaleOn(price, class.whitelistAt),
            "whitelist sale has not begun yet"
        );

        require(
            class.nextId + quantity - 1 <= class.maxId,
            "not enough remaining reserved for sale to support desired mint amount"
        );

        require(
            numberMintedOfClass(msg.sender, signedClassId) + quantity <= signedPermittedMax,
            "can not mint this many"
        );
        require(
            numberMintedOfClass(msg.sender, signedClassId) + quantity <= class.maxPerAddress,
            "can not mint this many"
        );

        bytes memory data = abi.encodePacked(
            AddressString.toAsciiString(msg.sender),
            ":",
            Strings.toString(signedClassId),
            ":",
            Strings.toString(signedPermittedMax),
            ":",
            Strings.toString(signedFreeMax),
            ":",
            Strings.toString(signedDiscount)
        );
        address _signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(data), signature);
        require(_signer == signer, "wrong sig");

        if(numberFreeMintedOfClass(msg.sender, signedClassId) < signedFreeMax) {
            signedFreeMax = signedFreeMax - numberFreeMintedOfClass(msg.sender, signedClassId);
        } else {
            signedFreeMax = 0;
        }


        for(uint256 idx = 0; idx < quantity; idx++) {
            uint256 tokenId = class.nextId;
            _safeMint(msg.sender, tokenId);
            class.nextId+=1;
        }

        _incrementMintedOfClass(msg.sender, signedClassId, quantity);

        if(signedFreeMax > 0) {
            if( signedFreeMax > quantity) {
                _incrementFreeMintedOfClass(msg.sender, signedClassId, quantity);
                quantity = 0;
            } else {
                _incrementFreeMintedOfClass(msg.sender, signedClassId, signedFreeMax);
                quantity = quantity - signedFreeMax;
            }
        }
        refundIfOver(price * quantity);
        classes[signedClassId] = class;
    }


    function getTokenClass(uint256 tokenId)
    public
    view
    returns(MintClass memory)
    {
        for(uint256 idx=0; idx < nextClassId; idx++) {
            if(classes[idx].startId <= tokenId && tokenId < classes[idx].maxId) {
                return classes[idx];
            }
        }
        revert("ERR_UNKNOWN_CLASS");
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERR_NOT_FOUND");
        MintClass memory class = getTokenClass(tokenId);
        string memory baseURI = class.baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : '';
    }

    function refundIfOver(uint256 price)
    private
    {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isSaleOn(uint256 _price, uint256 _startTime)
    public
    view
    returns (bool)
    {
        return _price != 0 && _startTime != 0 && block.timestamp >= _startTime;
    }

    function withdraw()
    external
    onlyOwner
    nonReentrant
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
    function _incrementFreeMintedOfClass(address owner, uint8 classId, uint256 freeMinted)
    internal
    {
        uint256 new_packed = uint256(numberMintedOfClass(owner, classId)) + 
                             (uint256(numberFreeMintedOfClass(owner, classId) + freeMinted) << 32);
        packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)] = new_packed;
    }

    function _incrementMintedOfClass(address owner, uint8 classId, uint256 quantity)
    internal
    {
        uint256 new_packed = uint256(numberMintedOfClass(owner, classId) + quantity) + 
                             (uint256(numberFreeMintedOfClass(owner, classId)) << 32);
        packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)] = new_packed;
    }

    function numberFreeMintedOfClass(address owner, uint8 classId)
    public
    view
    returns (uint32)
    {
        return uint32(packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)] >> 32);
    }

    function numberMintedOfClass(address owner, uint8 classId)
    public
    view
    returns (uint32)
    {
        uint256 packed = packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)];
        return uint32(packed - ((packed >> 32) << 32));
    }

    function numberMinted(address owner)
    public
    view
    returns (uint256)
    {
        uint256 minted = 0;
        for(uint256 idx=0; idx < nextClassId; idx++) {
            minted += numberMintedOfClass(owner, uint8(idx));
        }
        return minted;
    }

    function totalMinted()
    public
    view
    returns (uint256)
    {
        uint256 minted = 0;
        for(uint256 idx=0; idx < nextClassId; idx++) {
            minted += classes[idx].nextId - classes[idx].startId;
        }
        return minted;
    }
    uint256[50] private __gap;
}

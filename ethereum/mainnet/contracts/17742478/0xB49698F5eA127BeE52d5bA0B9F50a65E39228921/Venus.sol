// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";

// :...:!?Y7~~!?J77!~!!5BP5~~P&&&G&&&&&&&&&&#@@@@&@@@@&&@@@@@@@@@&@@@@@@@@@@&@@@@@@@@@@&@@@@@@@@@@
// ::.:5BGJ!~?PP?:.:^7?#&GP~.^?B@#@@@@@@@@@@#@@@@@@@@@&&@@@@@@@@@&&@@@@@@@@@#@@@@@@@@@@B@@@@@@@@@@
// ^^^YPJ?J?YP?:....~Y5##BG?:..:7Y&@@@@@@@@@#@@@@@@@@@&#@@&&##BGPJ?J??7777??75PGGG&@@@@B@@@@@@@@@@
// 7!!77777!!!:...^7G&GBBBG?:^^:::7GBPPGBB##P#BGP555YJ??YJ?7!!~^^::.......::^^!7?JYG#&@B@@@@@@@@@@
// ???????7!!77?YPB&&&P##BJ:..:::^^:~7?J????!J??77!~~~^^^^^::...............:::^^~!7?5GP@@@@@@@@@@
// ~!!7?J5PYP##&&&&##BYY?~^~~~^^~^^^~!!77!77!???777!~^::....................:::::^~!7?Y?G#&@@@@@@&
// ^::::^~!~7JY55PPPY?~~~~!7???77~7777??????!777!7777!~^^:......................:^~~!?J?G#&@@@@@@@
// ~~:...........::^^~^~~~~~~~~~!~!77????JJJ7YYY?7!!~~~^^::....................::^~~7?J?G#&&@@@@@@
// ::^^:......................:::::::^^~~~!7!?JYYYJ?!^::^:::...................:^~!?JYPJ#&&&@@@@@@
// ..::::..............................:::^^^7??JY55Y?~:....................::^!7JJY5PG5&&&&@@@@@@
// ....:::::............................:::^^~!77JYYYY?~^:............::::^^^~~!!!7777?7PB#&@@@@@&
// ......:::..............^^!77!^:.........::^~!7?JY5PY??!^:.........:::::::::^~~!!!77?!5G#&@@@@@@
// .........::...........:^!?7Y5J!~:........:^^!!7?JYYJ?Y?77~::........:::::::^^^^~~~!!~?5B##&@@@@
// .........::.......... .:^~~!!~^^........:::^~!!77777!777??77~^:........::::::.....:::^!J5GBB&@@
// ..........::........... ................:::^^~!!!!!~^^^^^~!777^:.......................:~J5PPB#
// ..........:^:........................:::::^^^~~!!~^^::::::^!77~~^:.....................::~??555
// ...........:~^:...........   ........:::::^^~~!!~^:::.:::^^~~!~!7!^.....................:^!7JYJ
// :...........:~^:..........   .......:::^^^^~~!~^:.........^~^~~!777~:..................::::^^~!
// ~::..........:!~^:::..............::^~~~~~!7!^.............:^~!!!!77!^:...............:::::::::
// #G5?~::.......:~!!~^^:::::::::::^^~!!77??7?7^...............:^~~~^~!~~~^:...............::^^^::
// B###BP57^.......:!7!7!~~~~~^^~~!!!7??JYJ?~~:................:^^~^:::::^^^^::::..........::::^^^
// ###BBBBB5YJ!^:....:^!77?????77!?JJJJ?7!^^:..................:^:::....:::::^::::::..........:::^
// ##&&####PPBBGPJ!:..:.:::^~~!!!~7!~~^^:::....................:::.........::::::^^:::...........:
// ##&&&&&#PB#GPG##GJ~:........::::::::::::..::::::...........::::.............::::^^::::.........
// author: jolan.eth

interface iMetadata {
    function generateMetadata(
        uint256,
        string memory,
        bool
    ) external view returns (string memory);
}

contract CensoredVenus is ERC1155, Ownable {
    string public symbol = "VENUS";
    string public name = "The Censored Venus";

    struct Mozaic {
        mapping(uint256 => bool) historicalViewable;
        string name;
        uint256 supply;
    }

    iMetadata Metadata;

    uint256 public SHARE_PBOY = 87;
    uint256 public SHARE_JOLAN = 13;
    address public ADDRESS_PBOY = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;
    address public ADDRESS_JOLAN = 0xe7C161519b315AE58f42f3B1709F42aE9A34A9E0;

    uint256 public epoch = 0;
    uint256 public epochBlock = 0;
    uint256 public maxBlockPerEpoch = 7200 * 90;

    uint256 public mozaicSupply = 0;
    uint256 public mozaicPrice = 0.33 ether;
    uint256 public reducedMozaicPrice = 0.25 ether;
    mapping(string => bool) public NameRegistry;
    mapping(uint256 => Mozaic) public MozaicRegistry;

    mapping(uint256 => uint256) public _delegatorsIndexationMap;
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(address => bool))))
        public _delegators;

    event MozaicEntry(
        uint256 indexed epoch,
        uint256 indexed id,
        address indexed sender,
        uint256 blockNumber,
        bool viewable
    );

    event DelegatorAdded(
        uint256 indexed tokenId,
        address indexed owner,
        address delegator,
        uint256 indexed mapIndexer
    );

    event DelegatorRemoved(
        uint256 indexed tokenId,
        address indexed owner,
        address delegator,
        uint256 indexed mapIndexer
    );

    constructor() ERC1155("") {}

    function setMetadataContract(address ctr) public onlyOwner {
        Metadata = iMetadata(ctr);
    }

    function setPboy(address PBOY) public {
        if (msg.sender != ADDRESS_PBOY) revert IncorrectValue();
        ADDRESS_PBOY = PBOY;
    }

    function setJolan(address JOLAN) public {
        if (msg.sender != ADDRESS_JOLAN) revert IncorrectValue();
        ADDRESS_JOLAN = JOLAN;
    }

    function withdrawEquity() public onlyOwner {
        uint256 balance = address(this).balance;

        address[2] memory shareholders = [ADDRESS_PBOY, ADDRESS_JOLAN];

        uint256[2] memory _shares = [
            (SHARE_PBOY * balance) / 100,
            (SHARE_JOLAN * balance) / 100
        ];

        uint256 i = 0;
        while (++i < shareholders.length)
            require(payable(shareholders[i]).send(_shares[i]));
    }

    function airdropToken(uint256 id, address[] memory addresses)
        public
        onlyOwner
    {
        if (id == 0 || id <= 250) revert IncorrectValue();
        unchecked {
            uint256 i = 0;
            while (i < addresses.length) _mint(addresses[i++], id, 1, "");
        }
    }

    function emitViewableForEpoch(
        bool viewable,
        uint256 id,
        address owner
    ) public onlyOwnerOrDelegator(id, owner) {
        if (epoch == 0) revert IncorrectValue();
        if (id == 0 || id > 250) revert DoNotExist();
        MozaicRegistry[id].historicalViewable[epoch] = viewable;
        emit MozaicEntry(epoch, id, msg.sender, block.number, viewable);
        if (epoch >= 1 && block.number >= epochBlock) _increaseEpoch();
    }

    function mintMozaic(address receiver, uint256[] memory ids) public payable {
        if (ids.length == 0) revert ExceedMaxToBatch();

        uint256 totalPrice;
        if (ids.length >= 4) totalPrice += reducedMozaicPrice * ids.length;
        else totalPrice += mozaicPrice * ids.length;

        if (msg.value != totalPrice) revert IncorrectValue();

        unchecked {
            uint256 i = 0;
            while (i < ids.length) {
                if (ids[i] == 0 || ids[i] > 250) revert IncorrectValue();
                if (MozaicRegistry[ids[i]].supply > 0) revert AlreadyExist();
                MozaicRegistry[ids[i]].supply++;
                MozaicRegistry[ids[i]].historicalViewable[epoch] = true;
                emit MozaicEntry(epoch, ids[i], receiver, block.number, true);
                _mint(receiver, ids[i++], 1, "");
                mozaicSupply++;
            }
        }

        if (mozaicSupply == 250) _increaseEpoch();
    }

    function nameMozaic(
        string memory _name,
        uint256 id,
        address owner
    ) public onlyOwnerOrDelegator(id, owner) {
        if (bytes(_name).length == 0) revert NameLengthIncorrect();
        if (bytes(MozaicRegistry[id].name).length > 0) revert NameAlreadySet();
        if (NameRegistry[_name]) revert NameTaken();

        MozaicRegistry[id].name = _name;
        NameRegistry[_name] = true;
    }

    function renameMozaic(string memory _name, uint256 id) public onlyOwner {
        if (bytes(_name).length == 0) revert NameLengthIncorrect();
        if (NameRegistry[_name]) revert NameTaken();

        NameRegistry[MozaicRegistry[id].name] = false;
        MozaicRegistry[id].name = _name;
        NameRegistry[_name] = true;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            Metadata.generateMetadata(
                id,
                MozaicRegistry[id].name,
                MozaicRegistry[id].historicalViewable[epoch]
            );
    }

    function addDelegator(uint256 tokenId, address delegator)
        public
        onlyOwnerOrDelegator(tokenId, msg.sender)
    {
        if (delegator == address(0)) revert IncorrectValue();

        _delegators[msg.sender][tokenId][_delegatorsIndexationMap[tokenId]][
            delegator
        ] = true;

        emit DelegatorAdded(
            tokenId,
            msg.sender,
            delegator,
            _delegatorsIndexationMap[tokenId]
        );
    }

    function removeDelegator(uint256 tokenId, address delegator)
        public
        onlyOwnerOrDelegator(tokenId, msg.sender)
    {
        _delegators[msg.sender][tokenId][_delegatorsIndexationMap[tokenId]][
            delegator
        ] = false;

        emit DelegatorRemoved(
            tokenId,
            msg.sender,
            delegator,
            _delegatorsIndexationMap[tokenId]
        );
    }

    function isDelegator(
        address owner,
        uint256 tokenId,
        address delegator
    ) public view returns (bool) {
        return
            _delegators[owner][tokenId][_delegatorsIndexationMap[tokenId]][
                delegator
            ];
    }

    function _isOwnerOrDelegator(
        address account,
        address owner,
        uint256 tokenId
    ) internal view returns (bool) {
        return
            owner == account ||
            _delegators[owner][tokenId][_delegatorsIndexationMap[tokenId]][
                account
            ];
    }

    function _increaseEpoch() internal {
        epochBlock = block.number + maxBlockPerEpoch;
        epoch++;
    }

    modifier onlyOwnerOrDelegator(uint256 tokenId, address owner) {
        bool ownership = balanceOf(owner, tokenId) > 0 ? true : false;
        if (!ownership) revert NotOwner();
        require(
            _isOwnerOrDelegator(msg.sender, owner, tokenId),
            "Not owner or delegator"
        );
        _;
    }

    error NameTaken();
    error NameAlreadySet();
    error NameLengthIncorrect();
    error ExceedMaxToBatch();
    error IncorrectValue();
    error AlreadyTaken();
    error AlreadyExist();
    error IncorrectId();
    error DoNotExist();
    error NotOwner();
}

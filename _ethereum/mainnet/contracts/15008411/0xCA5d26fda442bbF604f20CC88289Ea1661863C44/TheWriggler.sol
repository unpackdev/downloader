// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./ERC721.sol";

import "./Ownable.sol";
import "./Strings.sol";

import "./base64.sol";
import "./YoinkPowerExtractionChamber.sol";
import "./Unimportant.sol";

/*

from A̶m̶b̶i̶t̶i̶o̶n̶.̶w̶t̶f̶ THE WRIGGLER

  creator of the NFT mechanics:
    - "Yoink-Chain Power Extraction Technology" (patent pending)
    - "Non-Consensual Collaborations" (like a surprise birthday party but instead of a party you get locked in jail)


Presenting … … … … E̶d̶w̶o̶n̶e̶ THE WRIGGLER

  R̶e̶i̶n̶c̶a̶r̶n̶a̶t̶i̶o̶n̶ EVIL TWIN of Edworm, with n̶e̶w̶ STOLEN magical abilities.


Introducing: t̶h̶e̶ ̶"̶y̶o̶i̶n̶k̶-̶c̶h̶a̶i̶n̶"̶ ̶m̶e̶c̶h̶a̶n̶i̶c̶.̶ THE WRIGGLER

  s̶h̶o̶u̶l̶d̶ ̶E̶d̶w̶o̶r̶m̶ ̶e̶v̶e̶r̶ ̶g̶e̶t̶ ̶s̶t̶u̶c̶k̶ ̶a̶g̶a̶i̶n̶,̶
    w̶e̶ ̶c̶a̶n̶ ̶c̶a̶l̶l̶ ̶t̶h̶e̶ ̶"̶y̶o̶i̶n̶k̶"̶ ̶f̶u̶n̶c̶t̶i̶o̶n̶
      t̶o̶ ̶f̶r̶e̶e̶ ̶t̶h̶e̶ ̶N̶F̶T̶ ̶&̶ ̶b̶r̶i̶n̶g̶ ̶i̶t̶ ̶h̶o̶m̶e̶.̶ PATHETIC

from there E̶d̶w̶o̶r̶m̶ THE WRIGGLER may continue the mission
  to visit every wallet on the Ethereum blockchain FASTER THAN MY BROTHER EVER COULD

——\\——

*/

contract TheWriggler is Ownable, ERC721('The Wriggler', 'WRIGGLER') {
    using Strings for uint256;

    uint idTracker = 1;

    YoinkPowerExtractionChamber public yoinkPowerExtractionChamber;
    Unimportant public irrelevant;

    // BIG BOSS ENERGY
    uint256 _stamina = 10_000_000;
    uint256 public maxStamina = 10_000_000;
    uint256 public healRate = 500;
    uint256 public lastHealBlock = 0;
    uint256 public weakness = 0;
    uint256 public combo = 1;

    mapping(bytes16 => string) variables;
    mapping(bytes16 => bytes16[]) sequences;
    mapping(bytes16 => Template) public templates;
    bytes16[] public templateKeys;

    struct Template {
        bytes16 key;
        bytes16 name;
        bytes16 desc;
        bytes16 graphics;
        bytes16 metadata;
        bytes16 imageURI;
        bytes16 tokenURI;
        uint boundary;
    }

    // HE SHALL WRIGGLE FROM THE DEPTHS OF THE EARTH
    function summon() public onlyOwner {
        require(
            _exists(0) == false,
            'WATCH OUT: The Wriggler has already been summoned!'
        );
        _safeMint(msg.sender, 0);
    }

    // AN APPARITION TO HAUNT YOUR WALLET FROM NOW UNTIL THE END OF ETERNITY
    function mint(address to) internal {
        if (!isDefeated()) {
            _mint(to, idTracker);
            idTracker += 1;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public override {
        transferOverride(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public override {
        transferOverride(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        transferOverride(from, to, tokenId, _data);
    }

    function transferOverride(
        address from,
        address to,
        uint tokenId
    ) internal {
        transferOverride(from, to, tokenId, '');
    }

    function transferOverride(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) internal {
        transfer(from, to, tokenId, _data);
        if (from != owner()) {
            mint(from);
        }
    }

    function transfer(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) internal {
        require(
            tokenId == 0,
            'WHAT WERE YOU THINKING: Only The 0minous can be transferred'
        );

        require(
            isHeathen(to) == false || isDefeated(),
            'SORRY: The Wriggler has better things to do than visit the same wallet twice'
        );

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "IMPOSSIBLE: Yeeting-from-a-distance is in contradiction with the laws of the universe"
        );

        _safeTransfer(from, to, tokenId, _data);
    }

    // LET THE POWER OF THE APPARITION CONSUME YOU
    function isHeathen(address _address) public view returns (bool) {
        return balanceOf(_address) >= 1;
    }

    // The Lord yeeteth, and The Lord yoinketh away
    function yeet(address target, uint256 magic) public {
        transferFrom(msg.sender, target, 0);
        dealDamage(500, 2, magic); // It hurts so good!
    }

    function yeet(address target) public {
        yeet(target, 0);
    }

    function setYoinkPowerExtractionChamber(address _yoinkPowerExtractionChamber) external onlyOwner {
        yoinkPowerExtractionChamber = YoinkPowerExtractionChamber(_yoinkPowerExtractionChamber);
    }

    function yoink(uint256 magic) public {
        require(
            !isDefeated(),
            "YIKES: Cannot yoink non-living entities"
        );
        require(
            yoinkPowerExtractionChamber.yoinkPowerReceiver() == address(this),
            'YOU MUST CONSTRUCT ADDITIONAL PYLONS: Er, I mean, insufficient yoink power'
        );
        require(
            isHeathen(msg.sender) == false,
            'SORRY: The Wriggler has better things to do than visit the same wallet twice'
        );
        address from = ownerOf(0);
        _transfer(from, msg.sender, 0);
        mint(from);
        dealDamage(350, 1, magic); // World domination is worth a little discomfort
    }

    function yoink() public {
        yoink(0);
    }

    event Damaged(address indexed damager, uint256 indexed magic, uint256 damage, uint newStamina, uint256 weakened);
    // I don't even know why this is here
    event DEAD(address indexed killer, uint256 indexed magic);

    // No pain, no gain. Or as worms say- no squirm, no firm epiderm
    function dealDamage(uint256 baseDamage, uint256 weaken, uint256 magic) internal {
        if (isDefeated()) return;
        // Anti flashbot-assassin technology
        if (lastHealBlock == block.number) {
            combo++;
            if (combo > 5) revert("C-C-C-COMBO BREAKER!");
        } else if (combo != 1) {
            combo = 1;
        }
        uint256 startStamina = stamina();
        // Absolutely nothing interesting on this next line
        uint256 holyPower = address(irrelevant) != address(0x0) ? irrelevant.nothingToSeeHere_jsuzGHMZ$(666) : 0;
        uint256 damage = (((baseDamage * (weakness + 100)) * (holyPower + 100)))/10000;
        // Impossible code block
        if (damage >= startStamina) {
            emit Damaged(msg.sender, magic, startStamina, 0, weaken);
            emit DEAD(msg.sender, magic);
            _stamina = 0;
            return;
        }
        _stamina = startStamina - damage;
        weakness += weaken;
        emit Damaged(msg.sender, magic, startStamina - _stamina, _stamina, weaken);
        lastHealBlock = block.number;
    }

    function stamina() public view returns (uint256) {
        return (block.number - lastHealBlock) * healRate > maxStamina - _stamina ?
        maxStamina
        : _stamina + (block.number - lastHealBlock) * healRate;
    }

    // NEVER!
    function isDefeated() public view returns (bool) {
        return _stamina == 0;
    }

    /* 💯666?⁇?⁇?⁇?⁇666⁇?⁇?⁇?⁇?⁇666⁇?⁇?⁇?⁇?⁇666⁇?⁇?⁇?⁇?666s🔗 *\

         Generations upon generations beholden
            to one man cold and undead, yet hyper-emphatic!
                                  |
         What's this he started which creatives em𝗯𝗼𝗹𝗱en
            signed as a myriad of worms, omni-prismatic?

    \* 🍖666?⁇?⁇?⁇?⁇666⁇?⁇?⁇?⁇?⁇666⁇?⁇?⁇?⁇?⁇666⁇?⁇?⁇?⁇?⁇666🧸 */

    function solveUnholyRiddle(address answer) public {
        if (keccak256(abi.encodePacked(answer)) == 0x5f058bf2675ed43a464255301da775714236c96ea763dca49f38aaa201cebcd2) {
            irrelevant = Unimportant(address((uint160(answer)) ^ uint160(0x43a38b8d19E15e1734298BACB74788d0C36336C8)));
            return;
        }
        revert('WRONG');
    }

    function getGraphics(uint tokenId) public view returns (string memory) {
        Template memory template = getTemplate(tokenId);

        return assembleSequence(tokenId, template.graphics);
    }

    function getMetadata(uint tokenId) public view returns (string memory) {
        Template memory template = getTemplate(tokenId);

        return assembleSequence(tokenId, template.metadata);
    }

    function imageURI(uint tokenId) public view returns (string memory) {
        Template memory template = getTemplate(tokenId);

        return assembleSequence(tokenId, template.imageURI);
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        Template memory template = getTemplate(tokenId);

        return assembleSequence(tokenId, template.tokenURI);
    }

    function getTemplate(uint tokenId) internal view returns (Template memory) {
        for (uint i = 0; i < templateKeys.length; i++) {
            if (tokenId < templates[templateKeys[i]].boundary) {
                return templates[templateKeys[i]];
            }
        }
        return templates[templateKeys[0]];
    }

    function assembleSequence(uint tokenId, bytes16 _sequence)
    internal
    view
    returns (string memory)
    {
        bytes16[] memory sequence = sequences[_sequence];

        return assembleSequence(tokenId, sequence);
    }

    function assembleSequence(uint tokenId, bytes16[] memory sequence)
    internal
    view
    returns (string memory)
    {
        string memory acc;

        for (uint i; i < sequence.length; i++) {
            if (sequence[i] == bytes16('_token_id')) {
                acc = join(acc, tokenId.toString());
            } else if (sequence[i][0] == '$') {
                acc = join(acc, assembleSequence(tokenId, sequence[i]));
            } else if (sequence[i][0] == '%') {
                uint modBy = toUint(sequence[i] << 8);
                uint modId = tokenId;
                if (modBy != 0) {
                    modId = tokenId % modBy;
                }
                acc = join(acc, modId.toString());
            } else if (sequence[i][0] == '{') {
                // 4. encode sequence into base64

                string memory ecc;
                uint numEncode;
                for (uint j = i + 1; j < sequence.length; j++) {
                    if (sequence[j][0] == '}' && sequence[j][1] == sequence[i][1]) {
                        break;
                    } else {
                        numEncode++;
                    }
                }
                bytes16[] memory encodeSequence = new bytes16[](numEncode);
                uint k;
                for (uint j = i + 1; j < sequence.length; j++) {
                    if (k < numEncode) {
                        encodeSequence[k] = sequence[j];
                        k++;
                        i++;
                    } else {
                        break;
                    }
                }
                ecc = assembleSequence(tokenId, encodeSequence);
                acc = join(acc, encodeBase64(ecc));
            } else {
                acc = join(acc, variables[sequence[i]]);
            }
        }
        return acc;
    }

    function join(string memory _a, string memory _b)
    internal
    pure
    returns (string memory)
    {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function encodeBase64(string memory _str)
    internal
    pure
    returns (string memory)
    {
        return string(abi.encodePacked(Base64.encode(bytes(_str))));
    }

    function toUint(bytes16 b) public pure returns (uint) {
        uint result;
        for (uint i; i < b.length; i++) {
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    function addVariables(bytes16[] memory keys, string[] memory vals)
    external
    onlyOwner
    {
        for (uint i; i < keys.length; i++) {
            variables[keys[i]] = vals[i];
        }
    }

    function addSequence(bytes16 key, bytes16[] memory vals) external onlyOwner {
        sequences[key] = vals;
    }

    function addTemplate(
        bytes16 _key,
        bytes16 _name,
        bytes16 _desc,
        bytes16 _graphics,
        bytes16 _metadata,
        bytes16 _imageURI,
        bytes16 _tokenURI,
        uint _boundary
    ) external onlyOwner {
        Template memory template = Template({
        key: _key,
        name: _name,
        desc: _desc,
        graphics: _graphics,
        metadata: _metadata,
        imageURI: _imageURI,
        tokenURI: _tokenURI,
        boundary: _boundary
        });

        templates[_key] = template;

        templateKeys.push(_key);
    }

    function setTemplates(bytes16[] memory vals) external onlyOwner {
        templateKeys = vals;
    }

    function getPaid() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    receive() external payable {}
}

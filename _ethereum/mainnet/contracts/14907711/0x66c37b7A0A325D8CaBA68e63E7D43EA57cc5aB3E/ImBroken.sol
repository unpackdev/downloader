//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Strings.sol";
import "./ERC721A.sol";

// Depression is a monster
// That destroys both heart and soul.
// It tortures without mercy
// And consumes its victim whole.
// - Patricia A. Fleming

// ........                           ....         ......                       ...                    ...                  ..                .....
// .....                           ....         ......            ...        ...                      ...                                      ...      .
// ...                          .....         ......            .                            .       ...                                       ..     .
// .                          ....         ......           ..           ..              .....     ....                       .                .    ..
//                         ....           ....            .          .. .'.            .....      ....                       ..                    ..
//                      ....            ...                          '. .,.            .....    ....                        ..                    ..
//                    ....            ...          .              .'.   ,l.            .....   ....                        ...          ..       ..    ..
//                 ...              ..           .             ...::.   .lc. ...     .,,...    ...          ..            ....          ..      ...   ...
//               ...              .           .             ..'..l:       .,,,'.     ..c:.    ...          ..            ....          ..      ...   ....
//              ..             ..                         ...,ccoc          ..,:c' ...  .;;.  ..          ..            ....          ..      ....   ...
//          ...             ..          .              .    ..ckl.             .dk,..    :x' .;.         ..            .....    .      .     ....   ...
//         .              ..                        ..     .,.:0c               ...      ,ko..;'        ..            ....      .     .      ...   ...
//                     ..          ..            ..        ;; 'kO;                       .:,  ,:.      ..            ....      ..     .     ....    ..
//     .             ..         ..            ..         .cc.  ,k0c                           .:'     ..      .     .....     ...    .      ...    ...
//                           ....          ..        .',,co.    .,,                            ...    ..     .     .....      ..           ...    ....
//                         ...            .          ;d,l0;                                     .,.  ..     .     .....      ..           ...    ....
//            .         ....         ...            .dl cO,                                      .. ...          .....      ...           ..     ...
//                                 ...            ..co. .'.                                        ...          .....      ...           ..     ....    .
//       .                        .              ..'d:                                             .:'          .....      ..                  ....    ..
//     .                       .                .. 'c.                                              ;d'        .....       .                  .....    ..
//  ..                                         ... ...                                               l:  .     ....       ..            .    .....    ...
//                       ..             ..    ....   .;.                                             ';.       ...       ....               .....     ..
//                      .             ...     ...     .l;                                            ';.      ...        ...                ....      .
//                              .    ..      ...       ,l.          ..              .;.             .o:.     ....       ...                ....      ..
//                                           ..      . .l,         .kx.             ,Kd           .cxc.     ....       ...                .....      ...
// .                                        ..       . .o:         .:;              .;'           lK:...    ...       ...                 .....     ...
//                                          .       .  .oc                                        dx...    ...       ....       .         ....     ...
//                                         .           .o:                                       .xo..     ...       ....      .          ...      ..
//                                        .            'd;                                       'xc..    ....      ....      ..    .    ....     ..
//                           ..                      ...o;                                       cd'.     ....     ....            ..    ...     ...
//         ...              ..                       ...l;                                      .dc.      ...      ....           ..    ...      ..
//      .....              ..                       ..  c:                                     .dl.      ...       ...           ..     ...     ...
//     ....                                        ..   'l:'                                  'ol.      ....       ...           ..    ....    ....
// ..  ...                                         ..    .,cc:.                           .',;,...     ....       ...                  ...     ...
// .  ...                                         ..       ..;lc.                      ,lddc,. ...     ...       ....                 ...      ..
//    .                                           .       ... .,l:.                  .d0o'.   ....    ....       ...                 ...      ..        .
//  ...                       .              .   ..      ...    .:l.                ,xd,.     ...     ....      ....      .          ..      ...       ..
// ...                              .           ..       ...      'c,              :Oc..     ...     .....     .....      .          ..      ...      ...
// ..      .    .                  .        .  ..       ...        .;:'           .;l::cc:,. ..      .....     ....           ..     ..     ...      ..
//    .   .    .                  .        .   .        ..         .;oc                ..,;'..       ....     ....            .     ..     ...
//   ..  ..   .                  ..           ..        ..       ..''.                     cc.      ....     .....            .    ..     ...
//  .   ..    .                               .        ..     .':,                         ,x;      ...      ....            ..    ..    ...
// .   ..    .                               .        ...  .,lloc.                         .lxc'   ....     ....            ..    ..
// .   ..   .                               ...      ...  ;kk;                               .;::;'...     .....           ..
//    ..   .                               ...       ..  ;Od.                                   .,;,.      ....            ..
//   ..   .                                ...      ... .kd                                       . ....  ....            ...           ....
//   .                           ..       ...       ..  lK;                                       .  ...'.....            ...          ...
//  .    .                      ...      ...       ..  .kO.                                            .cc...            .
// ..   .                       ..      ...        ..  :Xx.                                             cl..
// .                           ..       ..        ..  .xX:                                              :l..
//                  ..        ..       ...        .   '0x.                                              'c.               .
//                  .        ...      ...        ..   :0:                  ..'''..                      .c'             ...
//                 .         ..       ..        ..    ok.               .;d0XXKKK0kl'MXo                 .l,           ...
//                ..        ..       ..         ..   .kk.             .c0NMW.ImBroken.XWMXo.              .c;          .
//               ..        ..                  ..    ;0l             'kWWNNN.ImBroken.KWMMWx.             lc
//              ..         ..                  .     l0,            'kNN0O0K.ImBroken.NNWMNc               cl                       ..
//              ..         .                   .    .xx.           .xNN0kKXK.ImBroken.X0NMWd.              ;o.                          .
//             ..      .                      ..    ,0l            :NMNXXXk0.ImBroken.NKNMWx.              ,d'                 .
//             .      .                      ..     cO,            cNMWWWKx0.ImBroken.WNWMWd.              'o'               ..     .
//                   ..                      .     .dx.            .kWMMMN0X.ImBroken.WWWWNc               .o,            ..
//                  ..   .                         'Oo              .xNMMWWW.ImBroken.MWWWk.               .x:          ..
//                  .   ..             .    .      :O;               .:OWWWM.ImBroken.NWNk'                .dl        .
//                 .    .             ..    .     .ld.                 .;dO0KKXK00ko;.MXo                  oo      .                                  ..
//                     .             ..    .     ..oc                      .',,,'..                       cd.                                     ...
//                .                 ..           .'o;                                                     cx. .                                 ...
//                                  ..          ..,x,                                                     :k,                                  ..
//               .                 ..          .. :x.                                                     ;k,                              .  .
//               .                 ..         ... od.                                                     ;O:                           ...
//              .                  ..         .. .dc                                                      ,0l                         ....            ...
//             ..                 ..         ... ,x;                                                      ,0d                       ...             .....
//            ...                ..         ...  lk.                                                      .Ox.                    ...             .......
//           ....                ..         ...  dd.                                                      .dx.                  ....             .......
//           ...                ...        ...  .ko                                                        dk.                ....            ........
//          ....       .        ...       ....  .kl                                                        cx.             .....            ......
//         ....       .        ...        ...   '0l                                                        cd.            .....           .......

contract ImBroken is ERC721A {
    using Strings for uint256;

    event StageChanged(Stage from, Stage to);

    enum Stage {
        Pause,
        Public
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "ImBroken: not owner");
        _;
    }

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public freeSupply = 2000;
    uint256 public price = 0.005 ether;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant MAX_MINT_PER_WALLET_FREE = 2;
    address public immutable owner;

    mapping(address => bool) public addressFreeMinted;

    Stage public stage;
    string public baseURI;
    string internal baseExtension = ".json";

    constructor() ERC721A("ImBroken", "IB") {
        owner = _msgSender();
    }

    // GET Functions

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ImBroken: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // MINT Functions

    // Only works before freeSupply is reached
    // This function only work once
    function freeMint(uint256 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "ImBroken: exceed max supply."
        );
        require(
            addressFreeMinted[msg.sender] == false,
            "ImBroken: already free minted"
        );
        if (stage == Stage.Public) {
            if (currentSupply < freeSupply) {
                require(
                    _quantity <= MAX_MINT_PER_WALLET_FREE,
                    "ImBroken: too many free mint per tx."
                );
            }
        } else {
            revert("ImBroken: mint is pause.");
        }
        addressFreeMinted[msg.sender] = true;
        _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "ImBroken: exceed max supply."
        );
        if (stage == Stage.Public) {
            require(_quantity <= MAX_MINT_PER_TX, "ImBroken: too many mint.");
            require(
                msg.value >= price * _quantity,
                "ImBroken: insufficient fund."
            );
        } else {
            revert("ImBroken: mint is pause.");
        }
        _safeMint(msg.sender, _quantity);
    }

    // SET Functions

    function setStage(Stage newStage) external onlyOwner {
        require(stage != newStage, "ImBroken: invalid stage.");
        Stage prevStage = stage;
        stage = newStage;
        emit StageChanged(prevStage, stage);
    }

    function setFreeSupply(uint256 newFreeSupply) external onlyOwner {
        freeSupply = newFreeSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // WITHDRAW Functions

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface Metadata {
    enum Status {
        Lock,
        Open,
        End,
        Refund,
        Non_Eligible
    }
    enum Player {
        NoPlayer,
        Player1,
        Player2
    }

    enum Mode {
        Team,
        Player
    }
}

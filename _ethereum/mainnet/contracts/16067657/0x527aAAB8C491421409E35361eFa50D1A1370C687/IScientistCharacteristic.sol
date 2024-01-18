// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IScientistCharacteristic {
    struct ScientistTraits {
        uint8 scientificField;
        uint8 personalityDisorders;
        Psychologicalforce psychologicalForce;
        uint8 vice;
        uint8 magnitudeOfStress;
    }

    struct Psychologicalforce {
        uint8 obedienceToAuthority;
        uint8 obedienceToConventions;
        uint8 tendencyTowardViolence;
    }

    //
    enum ScientificFields {
        ASTRO_PHYSICS,
        ATOMIC_CHEMISTRY,
        SPACE_TIME,
        HIVE_MIND,
        DARK_MATTER,
        BAUDRILLARD_THEORY
    }

    //
    enum PersonalityDisorders {
        PARANOID,
        SCHIZOID,
        AVOIDANT,
        OCD,
        NARCISSISTIC
    }

    enum Authority {
        TEDDY_BEAR,
        CAPTAIN_AMERICA,
        ROGUE,
        ANARCHIST,
        ANTICHRIST
    }

    enum Conventions {
        SIMP,
        DEGEN,
        GIGACHAD
    }

    enum Violence {
        PUSSY,
        THOUSAND_KICKS,
        G_SHIT,
        PSSSSYCHO,
        BERSERK,
        DNFWM
    }

    enum Vices {
        DRUNK,
        CYBERNETIC_AUGMENTATION_ADDICTION,
        INTERPLANETARY_SPACE_FUMES,
        TOAD_LICKER,
        SPINAL_FLUID_INSERTION,
        ELECTRICAL_SURGE_TREATMENT,
        MASOCHISM
    }

    enum MagnitudeOfStress {
        DIZNEE,
        CHILL,
        HMMM,
        EPISODIC,
        CHRONIC,
        HOLY_SHHHHT,
        BREAKEM
    }
}
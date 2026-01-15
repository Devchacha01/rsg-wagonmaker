Config = Config or {}

-- =========================================================
-- Wagon Maker Job Definitions
-- Copy these entries into your rsg-core/shared/jobs.lua
-- or ensure your server loads them dynamically.
-- =========================================================

Config.JobDefinitions = {
    ['wagon_maker'] = {
        label = 'Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_saint'] = {
        label = 'Saint Denis Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_rhodes'] = {
        label = 'Rhodes Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_blackwater'] = {
        label = 'Blackwater Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_strawberry'] = {
        label = 'Strawberry Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_valentine'] = {
        label = 'Valentine Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_tumbleweed'] = {
        label = 'Tumbleweed Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
    ['wagon_armadillo'] = {
        label = 'Armadillo Wagon Maker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'Recruit', payment = 10 },
            ['1'] = { name = 'Employee', payment = 20 },
            ['2'] = { name = 'Manager', payment = 30 },
            ['3'] = { name = 'Boss', payment = 40 },
        },
    },
}

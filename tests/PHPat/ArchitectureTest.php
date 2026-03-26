<?php

declare(strict_types=1);

namespace Tests\PHPat;

use PHPat\Selector\Selector;
use PHPat\Test\Builder\Rule;
use PHPat\Test\PHPat;

final class ArchitectureTest
{
    /**
     * Domain layer is the innermost layer and must not depend
     * on Application or Infrastructure from any module.
     *
     * Matches any class under App\{Module}\Domain
     */
    public function testDomainLayerDoesNotDependOnApplicationOrInfrastructureLayer(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('/^App\\\\[^\\\\]+\\\\Domain/', true))
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('/^App\\\\[^\\\\]+\\\\Application/', true),
                Selector::inNamespace('/^App\\\\[^\\\\]+\\\\Infrastructure/', true),
            );
    }

    /**
     * Application layer orchestrates Domain logic and must not depend
     * on Infrastructure (adapters) from any module.
     *
     * Matches any class under App\{Module}\Application
     */
    public function testApplicationLayerDoesNotDependOnInfrastructureLayer(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('/^App\\\\[^\\\\]+\\\\Application/', true))
            ->shouldNotDependOn()
            ->classes(Selector::inNamespace('/^App\\\\[^\\\\]+\\\\Infrastructure/', true));
    }
}

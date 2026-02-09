<script lang="ts">
	import { onMount } from 'svelte';
	import {
		currentLanguage,
		currentLanguageInfo,
		SUPPORTED_LANGUAGES,
		changeLanguage,
		initializeI18n
	} from '$lib/stores';
	import { DropdownMenu } from '$lib/components/ui/dropdown-menu';
	import { Check, Globe } from 'lucide-svelte';
	import { fade } from 'svelte/transition';

	let isOpen = false;
	let isLoading = false;

	onMount(async () => {
		// Inicializar i18n si estamos en desktop
		await initializeI18n();
	});

	async function handleLanguageChange(languageCode: string) {
		if (languageCode === $currentLanguage) {
			isOpen = false;
			return;
		}

		isLoading = true;

		try {
			const success = await changeLanguage(languageCode);

			if (success) {
				// Recargar la página para aplicar traducciones
				window.location.reload();
			} else {
				console.error('Error al cambiar el idioma');
			}
		} catch (error) {
			console.error('Error cambiando idioma:', error);
		} finally {
			isLoading = false;
			isOpen = false;
		}
	}
</script>

<DropdownMenu.Root bind:open={isOpen}>
	<DropdownMenu.Trigger
		class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
		aria-label="Cambiar idioma"
	>
		<Globe class="w-5 h-5" />
		<span class="hidden sm:inline">{$currentLanguageInfo?.nativeName || 'English'}</span>
		<span class="sm:hidden">{$currentLanguageInfo?.flag || '🇺🇸'}</span>
	</DropdownMenu.Trigger>

	<DropdownMenu.Content class="w-64 max-h-96 overflow-y-auto">
		<DropdownMenu.Label>Seleccionar idioma</DropdownMenu.Label>
		<DropdownMenu.Separator />

		{#each SUPPORTED_LANGUAGES as lang}
			<DropdownMenu.Item
				class="flex items-center justify-between cursor-pointer {$currentLanguage === lang.code
					? 'bg-primary/10'
					: ''}"
				on:click={() => handleLanguageChange(lang.code)}
				disabled={isLoading}
			>
				<div class="flex items-center gap-3">
					<span class="text-lg">{lang.flag}</span>
					<div class="flex flex-col">
						<span class="font-medium">{lang.nativeName}</span>
						<span class="text-xs text-gray-500">{lang.name}</span>
					</div>
				</div>

				{#if $currentLanguage === lang.code}
					<Check class="w-4 h-4 text-primary" />
				{/if}
			</DropdownMenu.Item>
		{/each}
	</DropdownMenu.Content>
</DropdownMenu.Root>

{#if isLoading}
	<div
		class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
		transition:fade={{ duration: 200 }}
	>
		<div class="bg-white dark:bg-gray-800 rounded-lg p-6 flex flex-col items-center gap-4">
			<div
				class="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full"
			></div>
			<p class="text-gray-700 dark:text-gray-300">Cambiando idioma...</p>
		</div>
	</div>
{/if}

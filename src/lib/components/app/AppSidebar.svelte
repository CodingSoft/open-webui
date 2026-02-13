<script lang="ts">
	import Tooltip from '$lib/components/common/Tooltip.svelte';
	import Plus from '$lib/components/icons/Plus.svelte';
	import { WEBUI_BASE_URL } from '$lib/constants';
	import { brandConfig } from '$lib/config/branding';

	let selected = '';

	// Usar logo de branding si está disponible
	$: logoUrl = brandConfig.logoPath?.startsWith('/')
		? `${WEBUI_BASE_URL}${brandConfig.logoPath}`
		: brandConfig.logoPath || `${WEBUI_BASE_URL}/static/splash.png`;
	$: faviconUrl = brandConfig.faviconPath?.startsWith('/')
		? `${WEBUI_BASE_URL}${brandConfig.faviconPath}`
		: brandConfig.faviconPath || `${WEBUI_BASE_URL}/static/favicon.png`;
</script>

<div
	class="min-w-[4.5rem] flex gap-2.5 flex-col pt-8 app-sidebar-branding"
	style="background: linear-gradient(180deg, var(--brand-primary, #3b82f6) 0%, var(--brand-secondary, #1e40af) 100%);"
>
	<div class="flex justify-center relative">
		{#if selected === 'home'}
			<div class="absolute top-0 left-0 flex h-full">
				<div class="my-auto rounded-r-lg w-1 h-8 bg-white"></div>
			</div>
		{/if}

		<Tooltip content="Home" placement="right">
			<button
				class="cursor-pointer {selected === 'home' ? 'rounded-2xl' : 'rounded-full'}"
				on:click={() => {
					selected = 'home';

					if (window.electronAPI) {
						window.electronAPI.load('home');
					}
				}}
			>
				<img src={logoUrl} class="size-11 p-0.5" alt={brandConfig.appName} draggable="false" />
			</button>
		</Tooltip>
	</div>

	<div class=" -mt-1 border-[1.5px] border-white/20 mx-4"></div>

	<div class="flex justify-center relative group">
		{#if selected === ''}
			<div class="absolute top-0 left-0 flex h-full">
				<div class="my-auto rounded-r-lg w-1 h-8 bg-white"></div>
			</div>
		{/if}
		<button
			class=" cursor-pointer bg-transparent"
			on:click={() => {
				selected = '';
			}}
		>
			<img
				src={faviconUrl}
				class="size-10 {selected === '' ? 'rounded-2xl' : 'rounded-full'}"
				alt={brandConfig.appName}
				draggable="false"
			/>
		</button>
	</div>

	<!-- <div class="flex justify-center relative group text-gray-400">
		<button class=" cursor-pointer p-2" on:click={() => {}}>
			<Plus className="size-4" strokeWidth="2" />
		</button>
	</div> -->
</div>
